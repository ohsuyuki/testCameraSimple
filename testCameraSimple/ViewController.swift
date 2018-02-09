//
//  ViewController.swift
//  testCameraSimple
//
//  Created by osu on 2018/02/08.
//  Copyright © 2018 osu. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    @IBOutlet weak var imageView: UIImageView!

    var session : AVCaptureSession? = nil
    var device : AVCaptureDevice? = nil
    var output : AVCaptureVideoDataOutput? = nil

    let queueImageProcess = DispatchQueue(label: "imageProcess")

    override func viewDidLoad() {
        super.viewDidLoad()

        // 全面のカメラを取得
        guard let device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front).devices.first else {
            clean()
            return
        }
        self.device = device

        // セッション作成
        self.session = AVCaptureSession()
        guard let session = self.session else {
            return
        }
        // 解像度の設定
        session.sessionPreset = .high

        // カメラをinputに
        var inputTmp: AVCaptureDeviceInput? = nil
        do {
            inputTmp = try AVCaptureDeviceInput(device: device)
        } catch {
            print(error.localizedDescription)
            clean()
            return
        }
        guard let input = inputTmp else {
            clean()
            return
        }
        guard session.canAddInput(input) == true else {
            clean()
            return
        }
        session.addInput(input)

        // outputの構成と設定
        self.output = AVCaptureVideoDataOutput()
        guard let output = self.output else {
            clean()
            return
        }
        output.videoSettings = [ kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA ]
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "tatsdxkpcg"))
        output.alwaysDiscardsLateVideoFrames = true
        guard session.canAddOutput(output) == true else {
            clean()
            return
        }
        session.addOutput(output)

        #if false
        // ouputの向きを縦向きに
        for connection in output.connections {
            guard connection.isVideoOrientationSupported == true else {
                continue
            }
            connection.videoOrientation = .portrait
        }
        #endif
    }

    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let image = imageFromSampleBuffer(sampleBuffer: sampleBuffer) else {
            return
        }

        DispatchQueue.main.sync {
            imageView.image = image
        }

        queueImageProcess.async {
            self.imageProcess(image)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewDidAppear(_ animated: Bool) {
        guard let session = self.session else {
            return
        }
        session.startRunning()
    }

    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let imageBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }

        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        guard let baseAddress: UnsafeMutableRawPointer = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0) else {
            return nil
        }

        let bytesPerRow: UInt = UInt(CVPixelBufferGetBytesPerRow(imageBuffer))
        let width: UInt = UInt(CVPixelBufferGetWidth(imageBuffer))
        let height: UInt = UInt(CVPixelBufferGetHeight(imageBuffer))

        let bitsPerCompornent: UInt = 8
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue).union(CGBitmapInfo.byteOrder32Little)
        guard let newContext: CGContext = CGContext(data: baseAddress, width: Int(width), height: Int(height), bitsPerComponent: Int(bitsPerCompornent), bytesPerRow: Int(bytesPerRow), space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: bitmapInfo.rawValue) else {
            return nil
        }

        guard let cgImage = newContext.makeImage() else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    private func imageProcess(_ image: UIImage) {
        // process
    }
    
    private func clean() {
        session = nil
        device = nil
        output = nil
    }
}

