//
//  PuzzleGridView.swift
//  Motipuz
//
//  Created by 高橋紬季 on 2025/10/15.
//

import UIKit

final class PuzzleGridView: UIView {
    
    var gridSize: Int = 3
    var image: UIImage?
    var filledPieces: Int = 0
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let cellWidth = rect.width / CGFloat(gridSize)
        let cellHeight = rect.height / CGFloat(gridSize)
        let totalPieces = gridSize * gridSize
        
        
        for i in 0..<totalPieces {
            let row = i / gridSize
            let col = i % gridSize
            let cellRect = CGRect(x: CGFloat(col) * cellWidth, y: CGFloat(row) * cellHeight, width: cellWidth, height: cellHeight)
            
            for i in 0..<totalPieces {
                let row = i / gridSize
                let col = i % gridSize
                let cellRect = CGRect(x: CGFloat(col) * cellWidth, y: CGFloat(row) * cellHeight, width: cellWidth, height: cellHeight)
                
                // 塗り分けだけ
                (i < filledPieces ? UIColor.systemBlue : UIColor.systemGray5).setFill()
                context.fill(cellRect)
                
                // 枠線は残しても消してもOK
                UIColor.white.setStroke()
                context.stroke(cellRect, width: 1)
            }
        }
    }
}
