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
        savePuzzleSnapshotFromTasks()
        print("task added, update puzzle")
    }
    // タスク追加時に「進捗 or ガイド」の画像を保存してカレンダーへ反映する
    private func savePuzzleSnapshotFromTasks() {
        let tasks = TaskManager.shared.dailyPuzzle.tasks
        guard !tasks.isEmpty else { return }
        let image = makePuzzleProgressImage(tasks: tasks, size: 300)
        if let data = image.pngData() {
            TaskManager.shared.dailyPuzzle.imageData = data
            TaskManager.shared.save()
            NotificationCenter.default.post(name: .puzzleImageUpdated, object: nil)
        }
    }
    
    func updatePuzzleImage() {
        let tasks = TaskManager.shared.dailyPuzzle.tasks
        guard !tasks.isEmpty else {
            puzzleImageView.image = nil
            TaskManager.shared.dailyPuzzle.imageData = nil
            TaskManager.shared.save()
            NotificationCenter.default.post(name: .puzzleImageUpdated, object: nil)
            return
        }
        
        let guideImage = makePuzzleGuideImage(
            tasks: tasks,
            size: 300
        )
        puzzleImageView.image = guideImage
        
        let hasPlacedPiece = tasks.contains { $0.isPlaced }
        if !hasPlacedPiece, let data = guideImage.pngData() {
            TaskManager.shared.dailyPuzzle.imageData = data
            TaskManager.shared.save()
            NotificationCenter.default.post(name: .puzzleImageUpdated, object: nil)
        }
    }
    
    func createPuzzlePieces() {
        let tasks = TaskManager.shared.dailyPuzzle.tasks
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
            
            if task.isDone && (task.isPlaced || previouslyPlacedIDs.contains(task.id)) {
                piece.restorePlacedState()
                view.addSubview(piece)
            } else {
                piece.setInTray()
                if task.isDone {
                    piece.unlock()
                } else {
                    piece.lock()
                }
            }
            
            
            pieces.append(piece)
            
            startAngle = endAngle
            piece.onPlaced = { [weak self] in
                self?.checkAllPlaced()
            }
        }
        
        trayCollectionView.reloadData()
        updateTrayButtons()
    }
    private func reloadPuzzleState() {
        updatePuzzleImage()
        createPuzzlePieces()
        checkClear()
    }
    func checkAllPlaced() {
        saveProgressSnapshot()
        let allPlaced = pieces.allSatisfy { $0.isPlaced }
        
        if allPlaced {
            let today = Calendar.current.startOfDay(for: Date())
            TaskManager.shared.saveDailyResult(date: today, isPerfect: true)
            saveCompletedSnapshot()
            showPerfectAnimation()
            showConfetti()
        }
    }
    
    // 1ピースでも置かれたら、現在の見た目をスナップショット保存する
    private func saveProgressSnapshot() {
        guard pieces.contains(where: { $0.isPlaced }) else { return }
        view.layoutIfNeeded()
        let targetFrame = puzzleImageView.frame
        let renderer = UIGraphicsImageRenderer(size: targetFrame.size)
        let image = renderer.image { context in
            context.cgContext.translateBy(x: -targetFrame.origin.x, y: -targetFrame.origin.y)
            view.layer.render(in: context.cgContext)
        }
        TaskManager.shared.dailyPuzzle.imageData = image.pngData()
        TaskManager.shared.save()
        NotificationCenter.default.post(name: .puzzleImageUpdated, object: nil)
    }
    
    // 全部置けたら、完成状態のスナップショットを保存する
    private func saveCompletedSnapshot() {
        view.layoutIfNeeded()
        let targetFrame = puzzleImageView.frame
        let renderer = UIGraphicsImageRenderer(size: targetFrame.size)
        let image = renderer.image { context in
            context.cgContext.translateBy(x: -targetFrame.origin.x, y: -targetFrame.origin.y)
            view.layer.render(in: context.cgContext)
        }
        TaskManager.shared.dailyPuzzle.imageData = image.pngData()
        TaskManager.shared.save()
        NotificationCenter.default.post(name: .puzzleImageUpdated, object: nil)
    }
    
    func makeGoldStarImage() -> CGImage? {
        let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .bold)
        let gold = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
        
        guard let symbol = UIImage(systemName: "star.fill", withConfiguration: config)?
            .withTintColor(gold, renderingMode: .alwaysOriginal)
        else {
            return nil
        }
        
        let renderer = UIGraphicsImageRenderer(size: symbol.size)
        let image = renderer.image { _ in
            symbol.draw(in: CGRect(origin: .zero, size: symbol.size))
        }
        
        return image.cgImage
    }
    func showPerfectAnimation() {
        let label = UILabel()
        label.text = "🎉 complete"
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textAlignment = .center
        label.alpha = 0
        label.center = view.center
        label.bounds.size = CGSize(width: 300, height: 60)
        
        view.addSubview(label)
        
        UIView.animate(withDuration: 0.4, animations: {
            label.alpha = 1
            label.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }) { _ in
            UIView.animate(withDuration: 0.6, delay: 1.5, animations: {
                label.alpha = 0
            }) { _ in
                label.removeFromSuperview()
            }
        }
        
        
        let cell = CAEmitterCell()
        cell.contents = makeGoldStarImage()
        
        cell.birthRate = 12
        cell.lifetime = 4
        cell.velocity = 180
        cell.velocityRange = 80
        cell.emissionLongitude = .pi
        cell.emissionRange = .pi / 3
        cell.spin = 4
        cell.spinRange = 6
        
        cell.scale = 0.15
        cell.scaleRange = 0.07
        
        
        cell.contentsScale = UIScreen.main.scale
        
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: view.bounds.midX, y: -10)
        emitter.emitterShape = .line
        emitter.emitterSize = CGSize(width: view.bounds.width, height: 1)
        emitter.emitterCells = [cell]
        
        view.layer.addSublayer(emitter)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            emitter.birthRate = 0
        }
        
        //  背景フラッシュ
        UIView.animate(withDuration: 0.2, animations: {
            self.view.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.15)
        }) { _ in
            UIView.animate(withDuration: 0.2) {
                self.view.backgroundColor = .systemBackground
            }
        }
        print(makeGoldStarImage() != nil)
        
    }
    func showConfetti() {
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: view.bounds.midX, y: -10)
        emitter.emitterShape = .line
        emitter.emitterSize = CGSize(width: view.bounds.size.width, height: 1)
        
        let colors: [UIColor] = [
            .systemRed, .systemBlue, .systemGreen,
            .systemYellow, .systemPink, .systemPurple
        ]
        
        emitter.emitterCells = colors.map { color in
            let cell = CAEmitterCell()
            cell.birthRate = 6
            cell.lifetime = 6.0
            cell.velocity = 180
            cell.velocityRange = 80
            cell.emissionLongitude = .pi
            cell.emissionRange = .pi / 4
            cell.spin = 3
            cell.spinRange = 4
            cell.scale = 0.05
            cell.scaleRange = 0.03
            cell.contents = makeGoldStarImage()
            return cell
        }
        
        view.layer.addSublayer(emitter)
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            emitter.birthRate = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                emitter.removeFromSuperlayer()
            }
        }
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
            let isUnlocked = TaskManager.shared.dailyPuzzle.tasks
                .first(where: { $0.id == piece.task.id })?
                .isDone ?? false
            // 未完了セルはグレー + lock アイコン
            cell.setLockedAppearance(!isUnlocked)
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
