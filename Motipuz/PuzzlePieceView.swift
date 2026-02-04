//
//  PuzzlePieceView.swift
//  Motipuz
//
//  Created by 高橋紬季 on 2026/01/23.
//


import UIKit

final class PuzzlePieceView: UIView {

    let task: Task

    private let pieLayer = CAShapeLayer()
    private var longPressGesture: UILongPressGestureRecognizer!
    private let puzzleRadius: CGFloat
    private var trayScale: CGFloat = 0.45
    private(set) var isInTray = false
    private let correctPieceCenter: CGPoint
    private let correctCenter: CGPoint
    private var trayCenter: CGPoint
    private weak var dragContainer: UIView?
    private var dragOffset: CGPoint = .zero
    private(set) var isPlaced = false
    private let angleMid: CGFloat
    private let visualRadius: CGFloat
    private var cachedVisualCenter: CGPoint?

    // MARK: - Init
    init(
        task: Task,
        startCenter: CGPoint,
        correctCenter: CGPoint,
        puzzleRadius: CGFloat,
        startAngle: CGFloat,
        endAngle: CGFloat
    ) {
        self.task = task
        self.puzzleRadius = puzzleRadius
        self.angleMid = (startAngle + endAngle) / 2
        self.visualRadius = puzzleRadius * 1.5
        // 円を正方形でマスクするためのViewサイズ
        let squareSide = puzzleRadius * 2

   

        // 正解位置（中心合わせ）
        self.correctCenter = correctCenter
        self.correctPieceCenter = correctCenter
        // トレイ位置（戻り先）
        self.trayCenter = startCenter
        
    
        


        super.init(frame: CGRect(
            x: 0,
            y: 0,
            width: squareSide,
            height: squareSide
        ))

        self.center = startCenter
        backgroundColor = .clear

        // ===== 円グラフ作成 =====
        let center = CGPoint(x: squareSide / 2, y: squareSide / 2)

        let piePath = UIBezierPath()
        
        
        piePath.move(to: center)
        piePath.addArc(
            withCenter: center,
            radius: visualRadius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true
        )
        piePath.close()

        pieLayer.path = piePath.cgPath
        pieLayer.fillColor = color(for: task).cgColor
        pieLayer.strokeColor = UIColor.darkGray.cgColor
        pieLayer.lineWidth = 2

        // ===== 正方形マスク =====
        let squareMask = CAShapeLayer()
        squareMask.path = UIBezierPath(rect: bounds).cgPath

        pieLayer.mask = squareMask
        layer.addSublayer(pieLayer)

        // ===== 長押しドラッグ =====
        longPressGesture = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleLongPress(_:))
        )
        longPressGesture.minimumPressDuration = 0.25
        longPressGesture.allowableMovement = 50
        addGestureRecognizer(longPressGesture)
        longPressGesture.isEnabled = false
        
        
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        print("didMoveToSuperview transform:", transform)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        _ = visualCenter()
    }
    
    // MARK: - Drag
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard !isPlaced else { return }
        switch gesture.state {
        case .began:
            beginDragIfNeeded()
            if let view = superview {
                let location = gesture.location(in: view)
                dragOffset = CGPoint(x: location.x - center.x, y: location.y - center.y)
            }
        case .changed:
            if let view = superview {
                let location = gesture.location(in: view)
                center = CGPoint(x: location.x - dragOffset.x, y: location.y - dragOffset.y)
            }
        case .ended, .cancelled, .failed:
            finishDrag()
        default:
            break
        }
    }

    private func beginDragIfNeeded() {
        if isInTray {
            isInTray = false
            UIView.animate(withDuration: 0.15) {
                self.transform = .identity
            }
            longPressGesture.isEnabled = true
        }
    }

    private func finishDrag() {
        let currentCenterInDrag: CGPoint
        if let dragContainer, let currentSuperview = superview {
            currentCenterInDrag = currentSuperview.convert(center, to: dragContainer)
        } else {
            currentCenterInDrag = center
        }

        let dx = currentCenterInDrag.x - correctCenter.x
        let dy = currentCenterInDrag.y - correctCenter.y
        let distance = hypot(dx, dy)

        let snapThreshold = puzzleRadius * 0.35
        print("距離:", distance, " / 閾値:", snapThreshold)

        if distance < snapThreshold {
            snap()
        } else {
            snapBackToTray()
        }
    }

    private func snap() {
        self.transform = .identity
        isPlaced = true
        if let dragContainer, let currentSuperview = superview, currentSuperview !== dragContainer {
            let centerInDrag = currentSuperview.convert(center, to: dragContainer)
            removeFromSuperview()
            dragContainer.addSubview(self)
            center = centerInDrag
        }
        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.8,
            options: [],
            animations: {
                self.center = self.correctPieceCenter
                self.transform = .identity
            }
        )
        TaskManager.shared.markPlaced(taskID: task.id)
    }
    
    private func snapBackToTray() {
        isInTray = true
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: [.beginFromCurrentState],
            animations: {
                self.center = self.trayCenter
                self.transform = CGAffineTransform(scaleX: self.trayScale, y: self.trayScale)
            },
            completion: { _ in
                if self.superview == nil {
                    self.onSnapBackToTray?(self)
                }
            }
        )
    }

    // MARK: - State
    func setInTray() {
        isInTray = true
        isPlaced = false
        trayCenter = center
        transform = CGAffineTransform(scaleX: trayScale, y: trayScale)
    }
    
    func setTrayCenterAligningVisualCenter(to targetCenter: CGPoint) {
        let visualOffset = visualCenterOffset()
        center = CGPoint(x: targetCenter.x - visualOffset.x, y: targetCenter.y - visualOffset.y)
        trayCenter = center
    }
    
    func setTrayScale(_ scale: CGFloat) {
        trayScale = scale
        if isInTray {
            transform = CGAffineTransform(scaleX: trayScale, y: trayScale)
        }
    }
    
    func setDragContainer(_ dragContainer: UIView) {
        self.dragContainer = dragContainer
    }

    var onSnapBackToTray: ((PuzzlePieceView) -> Void)?

    func unlock() {
        
        longPressGesture.isEnabled = true
    }

    func lock() {
        longPressGesture.isEnabled = false
    }

    private func visualCenterOffset() -> CGPoint {
        let c = visualCenter()
        let dx = c.x - bounds.midX
        let dy = c.y - bounds.midY
        return CGPoint(x: dx * trayScale, y: dy * trayScale)
    }

    private func visualCenter() -> CGPoint {
        if let cachedVisualCenter {
            return cachedVisualCenter
        }
        let size = bounds.size
        guard size.width > 1, size.height > 1 else {
            let fallback = CGPoint(x: bounds.midX, y: bounds.midY)
            cachedVisualCenter = fallback
            return fallback
        }

        let scale: CGFloat = 1
        let width = Int(size.width * scale)
        let height = Int(size.height * scale)
        let bytesPerRow = width * 4
        guard let ctx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            let fallback = CGPoint(x: bounds.midX, y: bounds.midY)
            cachedVisualCenter = fallback
            return fallback
        }

        ctx.setAllowsAntialiasing(true)
        ctx.translateBy(x: 0, y: CGFloat(height))
        ctx.scaleBy(x: scale, y: -scale)
        pieLayer.render(in: ctx)

        guard let data = ctx.data else {
            let fallback = CGPoint(x: bounds.midX, y: bounds.midY)
            cachedVisualCenter = fallback
            return fallback
        }

        let ptr = data.bindMemory(to: UInt8.self, capacity: width * height * 4)
        var sumX: CGFloat = 0
        var sumY: CGFloat = 0
        var count: CGFloat = 0

        for y in 0..<height {
            let row = y * bytesPerRow
            for x in 0..<width {
                let i = row + x * 4
                let alpha = ptr[i + 3]
                if alpha > 10 {
                    sumX += CGFloat(x)
                    sumY += CGFloat(y)
                    count += 1
                }
            }
        }

        if count > 0 {
            let cx = sumX / count
            let cy = sumY / count
            let result = CGPoint(x: cx / scale, y: cy / scale)
            cachedVisualCenter = result
            return result
        } else {
            let fallback = CGPoint(x: bounds.midX, y: bounds.midY)
            cachedVisualCenter = fallback
            return fallback
        }
    }

    func setInPuzzle() {
        isInTray = false
        transform = .identity
    }

    func restorePlacedState() {
        isPlaced = true
        isInTray = false
        transform = .identity
        center = correctPieceCenter
        longPressGesture.isEnabled = false
    }
}
