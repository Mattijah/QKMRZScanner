//
//  QKCutoutView.swift
//  QKMRZScanner
//
//  Created by Matej Dorcak on 05/10/2018.
//

import UIKit

class QKCutoutView: UIView {
    fileprivate(set) var cutoutRect: CGRect!

    private let cornerLength: CGFloat = 30
    private let cornerLineWidth: CGFloat = 4
    private let scanLineView = UIView()
    private var scanLineTopConstraint: NSLayoutConstraint?
    private var isAnimating = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.black.withAlphaComponent(0.45)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        recalculateCutoutRect()
        addCornerGuides()
        setupScanLine()
    }

    func startScanLineAnimation() {
        guard !isAnimating, cutoutRect != nil else { return }
        isAnimating = true
        animateScanLine()
    }

    func stopScanLineAnimation() {
        isAnimating = false
        scanLineView.layer.removeAllAnimations()
    }

    // MARK: Private
    fileprivate func recalculateCutoutRect() {
        let documentFrameRatio = CGFloat(1.42) // Passport's size (ISO/IEC 7810 ID-3) is 125mm x 88mm
        let (width, height): (CGFloat, CGFloat)

        if bounds.height > bounds.width {
            width = (bounds.width * 0.9) // Fill 90% of the width
            height = (width / documentFrameRatio)
        }
        else {
            height = (bounds.height * 0.75) // Fill 75% of the height
            width = (height * documentFrameRatio)
        }

        let topOffset = (bounds.height - height) / 2
        let leftOffset = (bounds.width - width) / 2

        cutoutRect = CGRect(x: leftOffset, y: topOffset, width: width, height: height)
    }

    private func addCornerGuides() {
        let maskLayer = CAShapeLayer()
        let path = CGMutablePath()
        let cornerRadius = CGFloat(10)

        path.addRoundedRect(in: cutoutRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius)
        path.addRect(bounds)

        maskLayer.path = path
        maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
        layer.mask = maskLayer

        // Remove old corner layers
        layer.sublayers?.filter { $0 is CAShapeLayer }.forEach { $0.removeFromSuperlayer() }

        let corners: [(CGPoint, Bool, Bool)] = [
            (CGPoint(x: cutoutRect.minX, y: cutoutRect.minY), true, true),   // top-left
            (CGPoint(x: cutoutRect.maxX, y: cutoutRect.minY), false, true),  // top-right
            (CGPoint(x: cutoutRect.minX, y: cutoutRect.maxY), true, false),  // bottom-left
            (CGPoint(x: cutoutRect.maxX, y: cutoutRect.maxY), false, false), // bottom-right
        ]

        for (point, isLeft, isTop) in corners {
            let cornerPath = UIBezierPath()

            let hDir: CGFloat = isLeft ? 1 : -1
            let vDir: CGFloat = isTop ? 1 : -1

            cornerPath.move(to: CGPoint(x: point.x + hDir * cornerLength, y: point.y))
            cornerPath.addLine(to: CGPoint(x: point.x + hDir * cornerRadius, y: point.y))
            cornerPath.addQuadCurve(
                to: CGPoint(x: point.x, y: point.y + vDir * cornerRadius),
                controlPoint: point
            )
            cornerPath.addLine(to: CGPoint(x: point.x, y: point.y + vDir * cornerLength))

            let cornerLayer = CAShapeLayer()
            cornerLayer.path = cornerPath.cgPath
            cornerLayer.strokeColor = UIColor.white.cgColor
            cornerLayer.fillColor = UIColor.clear.cgColor
            cornerLayer.lineWidth = cornerLineWidth
            cornerLayer.lineCap = .round
            layer.addSublayer(cornerLayer)
        }
    }

    private func setupScanLine() {
        guard cutoutRect != nil else { return }

        if scanLineView.superview == nil {
            scanLineView.translatesAutoresizingMaskIntoConstraints = false
            scanLineView.backgroundColor = UIColor.white.withAlphaComponent(0.6)
            scanLineView.layer.cornerRadius = 1
            addSubview(scanLineView)

            let topConstraint = scanLineView.topAnchor.constraint(equalTo: topAnchor, constant: cutoutRect.minY + 10)
            scanLineTopConstraint = topConstraint

            NSLayoutConstraint.activate([
                topConstraint,
                scanLineView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: cutoutRect.minX + 15),
                scanLineView.trailingAnchor.constraint(equalTo: leadingAnchor, constant: cutoutRect.maxX - 15),
                scanLineView.heightAnchor.constraint(equalToConstant: 2)
            ])
        } else {
            scanLineTopConstraint?.constant = cutoutRect.minY + 10
        }
    }

    private func animateScanLine() {
        guard isAnimating, cutoutRect != nil else { return }

        let startY = cutoutRect.minY + 10
        let endY = cutoutRect.maxY - 10

        scanLineTopConstraint?.constant = startY
        layoutIfNeeded()
        scanLineView.alpha = 0.6

        UIView.animate(withDuration: 2.0, delay: 0, options: [.curveEaseInOut], animations: {
            self.scanLineTopConstraint?.constant = endY
            self.layoutIfNeeded()
        }, completion: { [weak self] _ in
            UIView.animate(withDuration: 0.3, animations: {
                self?.scanLineView.alpha = 0
            }, completion: { [weak self] _ in
                self?.animateScanLine()
            })
        })
    }
}
