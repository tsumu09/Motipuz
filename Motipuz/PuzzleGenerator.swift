//
//  PuzzleGenerator.swift
//  Motipuz
//
//  Created by 高橋紬季 on 2025/12/02.
//

import UIKit

func makePuzzleGuideImage(tasks: [Task], size: CGFloat) -> UIImage {
    
    // ---- ① 円グラフ（ガイド）を描画 ----
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
    
    let pieImage = renderer.image { _ in
        let total = tasks.map { $0.value }.reduce(0, +)
        guard total > 0 else { return }
        
        let center = CGPoint(
            x: size / 2,
            y: size / 2
        )
        let radius = size / 2
        var startAngle: CGFloat = -.pi / 2
        
        UIColor.systemGray.setStroke()
        
        // 外周円
        let outerCircle = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: 0,
            endAngle: .pi * 2,
            clockwise: true
        )
        outerCircle.lineWidth = 2
        outerCircle.stroke()
        
        // 最後の境界線（円を閉じる）
        let lastLine = UIBezierPath()
        lastLine.move(to: center)
        lastLine.addLine(
            to: CGPoint(
                x: center.x + radius * cos(startAngle),
                y: center.y + radius * sin(startAngle)
            )
        )
        lastLine.lineWidth = 2
        lastLine.stroke()
        
        // 放射状の境界線
        for task in tasks {
            let value = CGFloat(task.value)
            let endAngle = startAngle + (value / CGFloat(total)) * 2 * .pi
            
            let linePath = UIBezierPath()
            linePath.move(to: center)
            linePath.addLine(
                to: CGPoint(
                    x: center.x + radius * cos(startAngle),
                    y: center.y + radius * sin(startAngle)
                )
            )
            linePath.lineWidth = 2
            linePath.stroke()
            
            startAngle = endAngle
        }
    }
    
    
    // ---- ② 円に内接する正方形にマスク ----
    let innerSide = size / sqrt(2)
    let offset = (size - innerSide) / 2
    
    let finalRenderer = UIGraphicsImageRenderer(
        size: CGSize(width: innerSide, height: innerSide)
    )
    
    return finalRenderer.image { _ in
        let clipPath = UIBezierPath(rect: CGRect(
            x: 0,
            y: 0,
            width: innerSide,
            height: innerSide
        ))
        clipPath.addClip()
        
        pieImage.draw(at: CGPoint(x: -offset, y: -offset))
    }
}
func color(for task: Task) -> UIColor {
    let hash = task.id.uuidString.hashValue
    let hue = CGFloat(abs(hash % 360)) / 360.0
    return UIColor(
        hue: hue,
        saturation: 0.7,
        brightness: 0.95,
        alpha: 1
    )
}

