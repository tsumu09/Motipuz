//
//  PuzzleViewController.swift
//  Motipuz
//
//  Created by 高橋紬季 on 2025/10/15.
//

import UIKit

class PuzzleViewController: UIViewController, AddTaskDelegate {
    private let taskManager = TaskManager.shared
    private var pieces: [PuzzlePieceView] = []
    
    @IBOutlet weak var puzzleImageView: UIImageView!
    @IBOutlet weak var trayView: UIView!
    var dailyPuzzle: DailyPuzzle = TaskManager.loadTodayPuzzle()

    override func viewDidLoad() {
        super.viewDidLoad()

        updatePuzzleImage()
        createPuzzlePieces()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(taskCompleted(_:)),
            name: .taskCompleted,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(checkClear),
            name: .piecePlaced,
            object: nil
        )
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nav = segue.destination as? UINavigationController,
           let addVC = nav.topViewController as? AddTaskViewController {
            addVC.delegate = self
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updatePuzzleImage()
    }
    
    @objc private func taskCompleted(_ notification: Notification) {
        guard let taskID = notification.object as? UUID else { return }

        if let piece = pieces.first(where: { $0.task.id == taskID }) {
            piece.unlock()
        }
    }
    
    @objc private func piecePlaced() {
        checkClear()
    }
    
    @objc private func checkClear() {
        let allPlaced = pieces.allSatisfy { $0.isPlaced }

        if allPlaced {
            showClearEffect()
        }
    }
    
    
    private func showClearEffect() {
        let label = UILabel()
        label.text = "COMPLETE!"
        label.font = .boldSystemFont(ofSize: 36)
        label.textColor = .systemYellow
        label.alpha = 0
        label.center = view.center
        view.addSubview(label)

        UIView.animate(withDuration: 0.6, animations: {
            label.alpha = 1
            label.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        })
    }
    
    func addTask(_ task: Task) {
        TaskManager.shared.addTask(task)
        dailyPuzzle = TaskManager.loadTodayPuzzle()
    }

    func didAddTask(_ task: Task) {
        TaskManager.shared.addTask(task)
        updatePuzzleImage()
        print("task added, update puzzle")
    }

    func updatePuzzleImage() {
        let tasks = TaskManager.shared.dailyPuzzle.tasks
        guard !tasks.isEmpty else {
            puzzleImageView.image = nil
            return
        }

        puzzleImageView.image = makePuzzleGuideImage(
            tasks: tasks,
            size: 300
        )
    }

    func createPuzzlePieces() {
        let tasks = TaskManager.shared.dailyPuzzle.tasks
        guard !tasks.isEmpty else { return }

        // 既存ピースを一旦削除
        pieces.forEach { $0.removeFromSuperview() }
        pieces.removeAll()

        let puzzleSize: CGFloat = 300
        let radius = puzzleSize / 2
        let total = tasks.map { $0.value }.reduce(0, +)
        guard total > 0 else { return }
        print("PUZZLE radius:", puzzleSize)
        // 正解位置（パズル中央）
        let imageFrame = puzzleImageView.imageFrameInView

        let correctCenter = trayView.convert(
            CGPoint(x: imageFrame.midX, y: imageFrame.midY),
            from: puzzleImageView
        )
        let dot = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        dot.backgroundColor = .red
        dot.layer.cornerRadius = 5
        dot.center = correctCenter
        trayView.addSubview(dot)
        
        
        // 🔽 トレイ内レイアウト設定
        let spacing: CGFloat = 20
        let scale: CGFloat = 0.45
       

        let trayWidth = trayView.bounds.width
        let squareSide = radius * 2.12
        let pieceSizeInTray = squareSide * scale
        let totalPiecesWidth =
            CGFloat(tasks.count) * pieceSizeInTray +
            CGFloat(tasks.count - 1) * spacing

        var currentX =
            max(spacing, (trayWidth - totalPiecesWidth) / 2) + pieceSizeInTray / 2

        let centerY = trayView.bounds.midY

        var startAngle: CGFloat = -.pi / 2

        for task in tasks {
            let value = CGFloat(task.value)
            let endAngle = startAngle + (value / CGFloat(total)) * 2 * .pi

            let startCenter = CGPoint(
                x: currentX,
                y: centerY
            )

            let piece = PuzzlePieceView(
                task: task,
                startCenter: startCenter,
                correctCenter: correctCenter,
                puzzleRadius: radius,
                startAngle: startAngle,
                endAngle: endAngle
            )
            trayView.addSubview(piece)
            piece.setInTray()
            
            let blue = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 8))
            blue.backgroundColor = .blue
            blue.layer.cornerRadius = 4
            blue.center = piece.center
            trayView.addSubview(blue)
            
            // 完了タスクだけアンロック
            if task.isDone {
                piece.unlock()
            }

            
            pieces.append(piece)

            currentX += pieceSizeInTray + spacing
            startAngle = endAngle
        }
    }
    
}
extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}
extension UIImageView {
    var imageFrameInView: CGRect {
        guard let image = image else { return bounds }

        let scale: CGFloat
        let imageRatio = image.size.width / image.size.height
        let viewRatio = bounds.width / bounds.height

        if imageRatio > viewRatio {
            scale = bounds.width / image.size.width
        } else {
            scale = bounds.height / image.size.height
        }

        let width = image.size.width * scale
        let height = image.size.height * scale

        let x = (bounds.width - width) / 2
        let y = (bounds.height - height) / 2

        return CGRect(x: x, y: y, width: width, height: height)
    }
}
