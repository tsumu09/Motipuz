//
//  PuzzleTrayCell.swift
//  Motipuz
//
//  Created by Codex on 2026/01/28.
//

import UIKit

final class PuzzleTrayCell: UICollectionViewCell {
    static let reuseIdentifier = "PuzzleTrayCell"

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.clipsToBounds = false
        clipsToBounds = false
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.systemGray4.cgColor
        contentView.layer.cornerRadius = 8
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        contentView.subviews.forEach { $0.removeFromSuperview() }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let piece = contentView.subviews.first as? PuzzlePieceView, piece.isInTray {
            let target = CGPoint(x: contentView.bounds.midX, y: contentView.bounds.midY)
            piece.setTrayCenterAligningVisualCenter(to: target)
        }
    }

    func setPiece(_ piece: PuzzlePieceView, dragContainer: UIView) {
        if piece.superview !== contentView {
            piece.removeFromSuperview()
            contentView.addSubview(piece)
        }
        let inset: CGFloat = 8
        let availableWidth = max(1, contentView.bounds.width - inset * 2)
        let availableHeight = max(1, contentView.bounds.height - inset * 2)
        let scale = min(availableWidth / piece.bounds.width, availableHeight / piece.bounds.height)
        piece.setTrayScale(scale)
        let target = CGPoint(x: contentView.bounds.midX, y: contentView.bounds.midY)
        piece.setTrayCenterAligningVisualCenter(to: target)
        piece.setDragContainer(dragContainer)
        piece.setInTray()
    }
}
