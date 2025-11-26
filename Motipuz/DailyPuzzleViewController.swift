//
//  DailyPuzzleViewController.swift
//  Motipuz
//
//  Created by 高橋紬季 on 2025/10/15.
//

import UIKit

class DailyPuzzleViewController: UIViewController {
    
    @IBOutlet weak var puzzleContainerView: UIView!
    @IBOutlet weak var puzzleStackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "今日のパズル"
    }
    
    func updatePuzzleView(tasks: [Task], total: Double = 1.0) {
        func randomColor() -> UIColor {
            return UIColor(
                red:   CGFloat.random(in: 0.3...0.9),
                green: CGFloat.random(in: 0.3...0.9),
                blue:  CGFloat.random(in: 0.3...0.9),
                alpha: 1.0
            )
        }

        // PuzzleStackView をクリア
        puzzleStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // 全体高さを取得（AutoLayout 内なら layoutIfNeeded 後に計算）
        let totalHeight = puzzleContainerView.bounds.height

        for task in tasks {
            let piece = UIView()
            piece.backgroundColor = randomColor()  // 好きに決めてOK
            piece.layer.cornerRadius = 8

            // 🔥 重さをそのまま使う （例：6 → 0.6 の扱いにしたいなら下で調整）
            let taskRatio = Double(task.weight) / total   // ← size の代わり！

            let height = totalHeight * taskRatio

            piece.heightAnchor.constraint(equalToConstant: height).isActive = true

            puzzleStackView.addArrangedSubview(piece)
        }

    }

}
extension UIView {
    func toImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: bounds.size)
        return renderer.image { _ in drawHierarchy(in: bounds, afterScreenUpdates: true) }
    }
}

