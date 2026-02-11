//
//  CalendarViewController.swift
//  Motipuz
//
//  Created by 高橋紬季 on 2025/10/15.
//

import UIKit
import FSCalendar

class CalendarViewController: UIViewController, FSCalendarDelegate, FSCalendarDataSource, FSCalendarDelegateAppearance {

    private var calendar = FSCalendar()
    private var puzzleImagesByDate: [Date: UIImage] = [:]
    // 連続で更新通知が来ても、1回だけ再描画するためのフラグ
    private var reloadScheduled = false
    
    @IBOutlet weak var perfectCountLabel: UILabel!
    
    var currentMonth: Date = Date()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "カレンダー"
        calendar.appearance.weekdayTextColor = .magenta
        calendar.appearance.headerTitleColor = .magenta
        calendar.appearance.borderRadius = 0
        calendar.appearance.selectionColor = .clear
        calendar.appearance.todayColor = .clear
        perfectCountLabel.font = UIFont.boldSystemFont(ofSize: 28)
        calendar.dataSource = self
        calendar.delegate = self
        calendar.register(CalendarPuzzleCell.self, forCellReuseIdentifier: CalendarPuzzleCell.reuseIdentifier)
        calendar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(calendar)

        currentMonth = calendar.currentPage
        updatePerfectCount(for: currentMonth)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(puzzleImageUpdated),
            name: .puzzleImageUpdated,
            object: nil
        )

        NSLayoutConstraint.activate([
            calendar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            calendar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            calendar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            calendar.heightAnchor.constraint(equalToConstant: 350)
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updatePerfectCount(for: currentMonth)
        // 画面に戻るタイミングでカレンダーをまとめて再描画する
        scheduleCalendarReload()
    }

    @objc private func puzzleImageUpdated() {
        // パズル画像が更新されたら、まとめて再描画を予約する
        scheduleCalendarReload()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        calendar.frame.size.height = 600
    }

    func perfectCount(for month: Date) -> Int {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: month),
              let firstDayOfMonth = calendar.date(
                  from: calendar.dateComponents([.year, .month], from: month)
              )
        else {
            return 0
        }

        var count = 0

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                let puzzle = TaskManager.loadPuzzle(for: date)

                if !puzzle.tasks.isEmpty &&
                    puzzle.tasks.allSatisfy({ $0.isDone }) {
                    count += 1
                }
            }
        }

        return count
    }
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {

        let puzzle = TaskManager.loadPuzzle(for: date)

        let vc = storyboard?.instantiateViewController(
            withIdentifier: "PuzzleDetailViewController"
        ) as! PuzzleDetailViewController

        vc.selectedDate = date
        vc.tasks = puzzle.tasks

        navigationController?.pushViewController(vc, animated: true)
    }

    func calendar(_ calendar: FSCalendar,
                  appearance: FSCalendarAppearance,
                  fillDefaultColorFor date: Date) -> UIColor? {
        return nil
    }

    func calendar(_ calendar: FSCalendar, cellFor date: Date, at position: FSCalendarMonthPosition) -> FSCalendarCell {
        let cell = calendar.dequeueReusableCell(withIdentifier: CalendarPuzzleCell.reuseIdentifier, for: date, at: position)
        if let puzzleCell = cell as? CalendarPuzzleCell {
            puzzleCell.puzzleImage = puzzleImageIfConfirmed(for: date)
        }
        return cell
    }

    func calendar(_ calendar: FSCalendar, willDisplay cell: FSCalendarCell, for date: Date, at position: FSCalendarMonthPosition) {
        if let puzzleCell = cell as? CalendarPuzzleCell {
            puzzleCell.puzzleImage = puzzleImageIfConfirmed(for: date)
        }
    }
    
    func showPuzzleDetail(for date: Date) {
        
        // その日のパズルを読み込む
        let puzzle = TaskManager.loadPuzzle(for: date)

        // ② 画面生成
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let detailVC = storyboard.instantiateViewController(
            withIdentifier: "PuzzleDetailViewController"
        ) as! PuzzleDetailViewController

        // ③ データを渡す
        detailVC.selectedDate = date
        detailVC.tasks = puzzle.tasks

        // ④ 画面遷移
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
        currentMonth = calendar.currentPage
        updatePerfectCount(for: currentMonth)
    }
    private func updatePerfectCount(for month: Date) {
        let count = perfectCount(for: month)
        perfectCountLabel.text = "🏆：\(count)日"
    }

    private func scheduleCalendarReload() {
        // すでに再描画予約があるなら、二重に予約しない
        guard !reloadScheduled else { return }
        reloadScheduled = true
        // 次の描画タイミングで1回だけreloadする
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.reloadScheduled = false
            self.calendar.reloadData()
        }
    }

    // カレンダーセルの背景に使う画像を決める（今日/過去で表示内容を分ける）
    private func puzzleImageIfConfirmed(for date: Date) -> UIImage? {
        if isToday(date) {
            // 今日のセルはその場でガイド画像を作る（タスク追加が即反映される）
            let puzzle = TaskManager.loadPuzzle(for: date)
            guard !puzzle.tasks.isEmpty else { return nil }
            if puzzle.tasks.contains(where: { $0.isPlaced }),
               let data = puzzle.imageData,
               let image = UIImage(data: data) {
                return image
            }
            // まだピースが置かれていない場合はガイド画像を表示
            return makePuzzleGuideImage(tasks: puzzle.tasks, size: 300)
        }
        // 昨日以前は保存済みの画像だけを表示する
        guard isConfirmedDate(date) else { return nil }
        let puzzle = TaskManager.loadPuzzle(for: date)
        guard let data = puzzle.imageData,
              let image = UIImage(data: data) else {
            return nil
        }
        return image
    }

    // 「昨日以前」の日付かどうか
    private func isConfirmedDate(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return calendar.startOfDay(for: date) < today
    }

    // 「今日」かどうか
    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

}

final class CalendarPuzzleCell: FSCalendarCell {
    static let reuseIdentifier = "CalendarPuzzleCell"
    private let puzzleImageView = UIImageView()

    var puzzleImage: UIImage? {
        didSet {
            puzzleImageView.image = puzzleImage
            titleLabel.textColor = (puzzleImage == nil) ? .label : .white
        }
    }

    override init!(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init!(coder aDecoder: NSCoder!) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        puzzleImageView.contentMode = .scaleAspectFill
        puzzleImageView.clipsToBounds = true
        contentView.insertSubview(puzzleImageView, at: 0)
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        puzzleImageView.frame = contentView.bounds
        titleLabel.frame = contentView.bounds
        titleLabel.textAlignment = .center
        contentView.bringSubviewToFront(titleLabel)
    }
}
