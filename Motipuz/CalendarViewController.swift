//
//  CalendarViewController.swift
//  Motipuz
//
//  Created by 高橋紬季 on 2025/10/15.
//

import UIKit
import FSCalendar

class CalendarViewController: UIViewController, FSCalendarDelegate, FSCalendarDataSource {

    private var calendar = FSCalendar()
    private var puzzleImagesByDate: [Date: UIImage] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "カレンダー"
        view.backgroundColor = .systemBackground

        calendar.dataSource = self
        calendar.delegate = self
        calendar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(calendar)

        NSLayoutConstraint.activate([
            calendar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            calendar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            calendar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            calendar.heightAnchor.constraint(equalToConstant: 350)
        ])
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        calendar.frame.size.height = 600
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

    func showPuzzleDetail(for date: Date) {
        
        // ① その日のパズルを読み込む（Dateのまま）
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



    
}
