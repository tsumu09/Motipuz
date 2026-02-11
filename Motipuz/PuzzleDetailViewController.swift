//
//  PuzzleDetailViewController.swift
//  Motipuz
//
//  Created by 高橋紬季 on 2025/11/12.
//

import UIKit

class PuzzleDetailViewController: UIViewController {
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var taskTableView: UITableView!

    var selectedDate: Date!
    var tasks: [Task] = []
    // その日のパズル（スナップショット/ガイド）をタスク一覧の上に表示する
    private let puzzleImageView = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        dateLabel.text = formatDate(selectedDate)

        // 正方形プレビューを目一杯表示するためにfillを使う
        puzzleImageView.contentMode = .scaleAspectFill
        puzzleImageView.clipsToBounds = true
        view.addSubview(puzzleImageView)

        taskTableView.dataSource = self
        taskTableView.delegate = self
        taskTableView.allowsSelection = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 画面外で画像が更新されている可能性があるため再読み込み
        updatePuzzleImage()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // プレビューを正方形に保ち、下のテーブルを詰め直す
        layoutPuzzleImage()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日（E）"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }

    private func updatePuzzleImage() {
        // 保存済みのimageData（完成スナップショット）を優先し、無ければガイド画像を使う
        let puzzle = TaskManager.loadPuzzle(for: selectedDate)
        if let data = puzzle.imageData, let image = UIImage(data: data) {
            puzzleImageView.image = image
        } else if !puzzle.tasks.isEmpty {
            puzzleImageView.image = makePuzzleGuideImage(tasks: puzzle.tasks, size: 300)
        } else {
            puzzleImageView.image = nil
        }
    }

    private func layoutPuzzleImage() {
        // 日付ラベルの下に横幅いっぱいの正方形を配置する
        let horizontalPadding: CGFloat = 24
        let top = dateLabel.frame.maxY + 12
        let size = max(0, view.bounds.width - horizontalPadding * 2)
        puzzleImageView.frame = CGRect(x: horizontalPadding, y: top, width: size, height: size)

        let tableTop = puzzleImageView.frame.maxY + 16
        let safeBottom = view.safeAreaInsets.bottom
        taskTableView.frame = CGRect(
            x: 0,
            y: tableTop,
            width: view.bounds.width,
            height: max(0, view.bounds.height - tableTop - safeBottom)
        )
    }
}

extension PuzzleDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tasks.count
    }
    
    func tableView(
            _ tableView: UITableView,
            cellForRowAt indexPath: IndexPath
        ) -> UITableViewCell {

            let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell")
            ?? UITableViewCell(style: .default, reuseIdentifier: "TaskCell")

            let task = tasks[indexPath.row]

            if task.isDone {
                cell.textLabel?.text = task.title
                cell.textLabel?.textColor = .secondaryLabel

                cell.imageView?.image = UIImage(systemName: "checkmark.circle.fill")
                cell.imageView?.tintColor = .magenta
            } else {
                cell.textLabel?.text = task.title
                cell.textLabel?.textColor = .label

                cell.imageView?.image = UIImage(systemName: "circle")
                cell.imageView?.tintColor = .systemGray3
            }
            return cell
        }
}
