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
        showPuzzleDetail(for: date)
    }

    func showPuzzleDetail(for date: Date) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let detailVC = storyboard.instantiateViewController(withIdentifier: "PuzzleDetailViewController") as! PuzzleDetailViewController
        detailVC.selectedDate = date
        detailVC.modalPresentationStyle = .pageSheet
        present(detailVC, animated: true)
    }



    
}
