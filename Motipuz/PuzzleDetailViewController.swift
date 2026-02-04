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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dateLabel.text = formatDate(selectedDate)
        
        taskTableView.dataSource = self
        taskTableView.delegate = self
        taskTableView.allowsSelection = false
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日（E）"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
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
