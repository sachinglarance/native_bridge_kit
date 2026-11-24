import AVFoundation
import UIKit

enum ScanOutcome {
  case success(String)
  case cancelled
  case failure(String)
}

/// Full-screen AVFoundation scanner for QR codes and common barcodes.
final class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
  private let session = AVCaptureSession()
  private let sessionQueue = DispatchQueue(label: "qr.session")
  private var previewLayer: AVCaptureVideoPreviewLayer?
  private let completion: (ScanOutcome) -> Void
  private var finished = false

  init(completion: @escaping (ScanOutcome) -> Void) {
    self.completion = completion
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black

    guard let camera = AVCaptureDevice.default(for: .video),
      let input = try? AVCaptureDeviceInput(device: camera),
      session.canAddInput(input)
    else {
      // e.g. the iOS simulator, which has no camera.
      DispatchQueue.main.async { self.finish(.failure("Camera is not available on this device")) }
      return
    }
    session.addInput(input)

    let output = AVCaptureMetadataOutput()
    guard session.canAddOutput(output) else {
      DispatchQueue.main.async { self.finish(.failure("Could not read camera output")) }
      return
    }
    session.addOutput(output)
    output.setMetadataObjectsDelegate(self, queue: .main)
    output.metadataObjectTypes = [.qr, .code128, .ean13].filter { output.availableMetadataObjectTypes.contains($0) }

    let layer = AVCaptureVideoPreviewLayer(session: session)
    layer.videoGravity = .resizeAspectFill
    view.layer.addSublayer(layer)
    previewLayer = layer

    addOverlay()
    sessionQueue.async { self.session.startRunning() }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    previewLayer?.frame = view.bounds
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    sessionQueue.async { self.session.stopRunning() }
  }

  private func addOverlay() {
    let close = UIButton(type: .close)
    close.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
    close.translatesAutoresizingMaskIntoConstraints = false

    let hint = UILabel()
    hint.text = "Point the camera at a QR code or barcode"
    hint.textColor = .white
    hint.backgroundColor = UIColor.black.withAlphaComponent(0.55)
    hint.textAlignment = .center
    hint.layer.cornerRadius = 8
    hint.clipsToBounds = true
    hint.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(close)
    view.addSubview(hint)
    NSLayoutConstraint.activate([
      close.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
      close.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      hint.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
      hint.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      hint.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.85),
      hint.heightAnchor.constraint(equalToConstant: 44),
    ])
  }

  @objc private func cancelTapped() { finish(.cancelled) }

  func metadataOutput(
    _ output: AVCaptureMetadataOutput,
    didOutput metadataObjects: [AVMetadataObject],
    from connection: AVCaptureConnection
  ) {
    guard let code = metadataObjects.compactMap({ $0 as? AVMetadataMachineReadableCodeObject }).first?.stringValue
    else { return }
    finish(.success(code))
  }

  /// Guarantees the Flutter result is completed exactly once.
  private func finish(_ outcome: ScanOutcome) {
    guard !finished else { return }
    finished = true
    if presentingViewController != nil {
      dismiss(animated: true) { self.completion(outcome) }
    } else {
      completion(outcome)
    }
  }
}
