//
//  PuzzleTrayCell.swift
//  Motipuz
//
//  Created by Codex on 2026/01/28.
//

import UIKit

final class PuzzleTrayCell: UICollectionViewCell {
    static let reuseIdentifier = "PuzzleTrayCell"

    // 未完了タスク用の見た目（グレー表示）を重ねるビュー
        private let lockOverlay = UIView()
        private let lockIconView = UIImageView(image: UIImage(systemName: "lock.fill"))
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.clipsToBounds = false
        clipsToBounds = false
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.systemGray4.cgColor
        contentView.layer.cornerRadius = 8
        
        lockOverlay.backgroundColor = UIColor.systemGray.withAlphaComponent(0.25)
                lockOverlay.layer.cornerRadius = 8
                lockOverlay.translatesAutoresizingMaskIntoConstraints = false
                lockOverlay.isHidden = true

                lockIconView.tintColor = .secondaryLabel
                lockIconView.translatesAutoresizingMaskIntoConstraints = false
                lockIconView.isHidden = true

                contentView.addSubview(lockOverlay)
                contentView.addSubview(lockIconView)
                NSLayoutConstraint.activate([
                    lockOverlay.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                    lockOverlay.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                    lockOverlay.topAnchor.constraint(equalTo: contentView.topAnchor),
                    lockOverlay.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                    lockIconView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                    lockIconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                    lockIconView.widthAnchor.constraint(equalToConstant: 18),
                    lockIconView.heightAnchor.constraint(equalToConstant: 18)
                ])
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        contentView.subviews.compactMap { $0 as? PuzzlePieceView }.forEach { $0.removeFromSuperview() }
                lockOverlay.isHidden = true
                lockIconView.isHidden = true
                contentView.alpha = 1.0
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let piece = contentView.subviews.first(where: { $0 is PuzzlePieceView }) as? PuzzlePieceView,
                  piece.isInTray {
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
    
    func setLockedAppearance(_ isLocked: Bool) {
            // lock表示をピースより前面に出す
            contentView.bringSubviewToFront(lockOverlay)
            contentView.bringSubviewToFront(lockIconView)
            lockOverlay.isHidden = !isLocked
            lockIconView.isHidden = !isLocked
            contentView.alpha = isLocked ? 0.8 : 1.0
        }
}
