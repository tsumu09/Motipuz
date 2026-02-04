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
    private var trayPieces: [PuzzlePieceView] { pieces.filter { $0.isInTray } }
    
    @IBOutlet weak var puzzleImageView: UIImageView!
    @IBOutlet weak var trayCollectionView: UICollectionView!
    @IBOutlet weak var trayLeftButton: UIButton!
    @IBOutlet weak var trayRightButton: UIButton!
    var dailyPuzzle: DailyPuzzle = TaskManager.loadTodayPuzzle()

    override func viewDidLoad() {
        super.viewDidLoad()

        trayCollectionView.dataSource = self
        trayCollectionView.delegate = self
        trayCollectionView.register(PuzzleTrayCell.self, forCellWithReuseIdentifier: PuzzleTrayCell.reuseIdentifier)
        trayCollectionView.showsHorizontalScrollIndicator = false
        trayCollectionView.clipsToBounds = false
        trayCollectionView.isScrollEnabled = false
        if let layout = trayCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
            layout.minimumLineSpacing = 12
            layout.minimumInteritemSpacing = 12
            layout.sectionInset = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
            layout.estimatedItemSize = .zero
        }

        reloadPuzzleState()
        updateTrayButtons()

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
        reloadPuzzleState()
    }
    
    @objc private func taskCompleted(_ notification: Notification) {
        guard notification.object as? UUID != nil else { return }
                reloadPuzzleState()
    }
    
    @objc private func piecePlaced() {
        checkClear()
    }
    
    @objc private func checkClear() {
        let allPlaced = !pieces.isEmpty && pieces.allSatisfy { $0.isPlaced }

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
        reloadPuzzleState()
        print("task added, update puzzle")
    }

    func updatePuzzleImage() {
        let tasks = TaskManager.shared.dailyPuzzle.tasks.filter { $0.isDone }
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
        let tasks = TaskManager.shared.dailyPuzzle.tasks.filter { $0.isDone }
                let previouslyPlacedIDs = Set(pieces.filter { $0.isPlaced }.map { $0.task.id })

                // 既存ピースを画面・トレイ両方から除去してから作り直す
                for piece in pieces {
                    piece.removeFromSuperview()
                }
                pieces.removeAll()
                view.layoutIfNeeded()

                guard !tasks.isEmpty else {
                    trayCollectionView.reloadData()
                    updateTrayButtons()
                    return
                }
        let puzzleSize: CGFloat = 300
        let radius = puzzleSize / 2
        let total = tasks.map { $0.value }.reduce(0, +)
        guard total > 0 else {
                    trayCollectionView.reloadData()
                    updateTrayButtons()
                    return
                }
        // 正解位置（パズル中央）
        let imageFrame = puzzleImageView.imageFrameInView
        let correctCenter = view.convert(
            CGPoint(x: imageFrame.midX, y: imageFrame.midY),
            from: puzzleImageView
        )
        
        var startAngle: CGFloat = -.pi / 2

        for task in tasks {
            let value = CGFloat(task.value)
            let endAngle = startAngle + (value / CGFloat(total)) * 2 * .pi

            let piece = PuzzlePieceView(
                task: task,
                startCenter: .zero,
                correctCenter: correctCenter,
                puzzleRadius: radius,
                startAngle: startAngle,
                endAngle: endAngle
            )
            piece.onSnapBackToTray = { [weak self] piece in
                self?.returnPieceToTray(piece)
            }
            piece.setDragContainer(view)

                        if task.isPlaced || previouslyPlacedIDs.contains(task.id) {
                            piece.restorePlacedState()
                            view.addSubview(piece)
                        } else {
                            piece.setInTray()
                piece.unlock()
            }

            
            pieces.append(piece)

            startAngle = endAngle
        }
        
        trayCollectionView.reloadData()
        updateTrayButtons()
    }
    private func reloadPuzzleState() {
            updatePuzzleImage()
            createPuzzlePieces()
            checkClear()
        }

}

// MARK: - Tray Scroll Buttons
extension PuzzleViewController {
    @IBAction func scrollTrayLeft(_ sender: UIButton) {
        scrollTray(by: -1)
    }

    @IBAction func scrollTrayRight(_ sender: UIButton) {
        scrollTray(by: 1)
    }

    private func scrollTray(by delta: Int) {
        let count = trayPieces.count
        guard count > 0 else { return }
        let itemsPerPage = 2
        let maxPage = max(0, (count - 1) / itemsPerPage)
        let currentPage = currentTrayPage(itemsPerPage: itemsPerPage)
        let targetPage = max(0, min(maxPage, currentPage + delta))
        let targetIndex = targetPage * itemsPerPage
        let indexPath = IndexPath(item: min(targetIndex, count - 1), section: 0)
        scrollTrayTo(indexPath: indexPath, animated: true)
        updateTrayButtons(targetPage: targetPage, maxPage: maxPage)
    }

    private func currentTrayPage(itemsPerPage: Int) -> Int {
        let offset = trayCollectionView.contentOffset.x + trayCollectionView.adjustedContentInset.left
        let pageWidth = max(1, trayCollectionView.bounds.width)
        return Int(round(offset / pageWidth))
    }

    private func scrollTrayTo(indexPath: IndexPath, animated: Bool) {
        trayCollectionView.layoutIfNeeded()
        if let layout = trayCollectionView.collectionViewLayout as? UICollectionViewFlowLayout,
           let attrs = layout.layoutAttributesForItem(at: indexPath) {
            let x = attrs.frame.minX - layout.sectionInset.left
            trayCollectionView.setContentOffset(CGPoint(x: x, y: 0), animated: animated)
        } else {
            trayCollectionView.scrollToItem(at: indexPath, at: .left, animated: animated)
        }
    }

    private func updateTrayButtons(targetPage: Int? = nil, maxPage: Int? = nil) {
        let itemsPerPage = 2
        let count = trayPieces.count
        let maxP = maxPage ?? max(0, (count - 1) / itemsPerPage)
        let currentP = targetPage ?? currentTrayPage(itemsPerPage: itemsPerPage)

        let leftEnabled = currentP > 0
        let rightEnabled = currentP < maxP

        trayLeftButton.isEnabled = leftEnabled
        trayRightButton.isEnabled = rightEnabled
        trayLeftButton.alpha = leftEnabled ? 1.0 : 0.3
        trayRightButton.alpha = rightEnabled ? 1.0 : 0.3
    }
}

extension PuzzleViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        trayPieces.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PuzzleTrayCell.reuseIdentifier,
            for: indexPath
        ) as! PuzzleTrayCell

        let piece = trayPieces[indexPath.item]
        piece.onSnapBackToTray = { [weak self] piece in
            self?.returnPieceToTray(piece)
        }

        if piece.isInTray {
            cell.setPiece(piece, dragContainer: view)
        }

        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else {
            let width = max(1, collectionView.bounds.width / 2)
            return CGSize(width: width, height: collectionView.bounds.height)
        }
        let insets = layout.sectionInset
        let spacing = layout.minimumLineSpacing
        let availableWidth = collectionView.bounds.width - insets.left - insets.right - spacing
        let width = max(1, availableWidth / 2)
        let height = width
        return CGSize(width: width, height: height)
    }
}

private extension PuzzleViewController {
    func returnPieceToTray(_ piece: PuzzlePieceView) {
        piece.removeFromSuperview()
               trayCollectionView.reloadData()
               updateTrayButtons()
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
