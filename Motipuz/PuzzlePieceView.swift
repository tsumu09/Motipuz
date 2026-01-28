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
    private var panGesture: UIPanGestureRecognizer!
    private let puzzleRadius: CGFloat
    private let trayScale: CGFloat = 0.45
    private var isInTray = false
    private let correctPieceCenter: CGPoint
    private(set) var isPlaced = false
    private let angleMid: CGFloat
    private let visualRadius: CGFloat

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
        // 円の直径
        let circleDiameter = puzzleRadius * 2

        // 円を正方形でマスクするためのViewサイズ
        let squareSide = puzzleRadius * 2

   

        // 正解位置用（吸い付き判定）
        let pieceOffset = puzzleRadius * 0.45

        self.correctPieceCenter = CGPoint(
            x: correctCenter.x + cos(angleMid) * pieceOffset,
            y: correctCenter.y + sin(angleMid) * pieceOffset
        )
        
    
        


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

        // ===== ドラッグ =====
        panGesture = UIPanGestureRecognizer(
            target: self,
            action: #selector(handlePan(_:))
        )
        addGestureRecognizer(panGesture)
        panGesture.isEnabled = false
        
        
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        print("didMoveToSuperview transform:", transform)
    }
    
    // MARK: - Drag
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard !isPlaced else { return }
        if gesture.state == .began && isInTray {
            isInTray = false

            let currentCenter = self.center

            UIView.animate(withDuration: 0.15) {
                self.transform = .identity
                self.center = currentCenter
            }
        }
        
        let t = gesture.translation(in: superview)
        center.x += t.x
        center.y += t.y
        gesture.setTranslation(.zero, in: superview)

        if gesture.state == .ended {

            let pieceOffset = puzzleRadius * 0.45

            let visualCenter = CGPoint(
                x: center.x + cos(angleMid) * (visualRadius - pieceOffset),
                y: center.y + sin(angleMid) * (visualRadius - pieceOffset)
            )

            let correctVisualCenter = CGPoint(
                x: correctPieceCenter.x + cos(angleMid) * (visualRadius - pieceOffset),
                y: correctPieceCenter.y + sin(angleMid) * (visualRadius - pieceOffset)
            )

            let dx = visualCenter.x - correctVisualCenter.x
            let dy = visualCenter.y - correctVisualCenter.y
            let distance = hypot(dx, dy)

            let snapThreshold = puzzleRadius * 0.4
            print("距離:", distance, " / 閾値:", snapThreshold)

            if distance < snapThreshold {
                snap()
            }
        }
    }

    private func snap() {
        self.transform = .identity
        isPlaced = true
        panGesture.isEnabled = false
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
    }

    // MARK: - State
    func setInTray() {
        isInTray = true
        transform = CGAffineTransform(scaleX: trayScale, y: trayScale)
    }

    func unlock() {
        
        panGesture.isEnabled = true
    }

    func setInPuzzle() {
        transform = .identity
    }
}
