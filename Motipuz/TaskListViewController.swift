//
//  TaskListViewController.swift
//  Motipuz
//
//  Created by 高橋紬季 on 2025/10/15.
//

import UIKit

class TaskListViewController: UIViewController, AddTaskDelegate{
    
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addButton: UIButton!
    
    private let taskManager = TaskManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                            target: self,
                                                            action: #selector(addButtonTapped))
        setupTableView()
        navigationController?.navigationBar.tintColor = .magenta
        
        tableView.dataSource = self
                tableView.delegate = self
                
                // 見た目の設定（＋ボタンを丸く）
                addButton.layer.cornerRadius = addButton.frame.height / 2
                addButton.backgroundColor = UIColor.systemBlue
                addButton.setTitle("+", for: .normal)
                addButton.titleLabel?.font = UIFont.systemFont(ofSize: 30, weight: .bold)
                addButton.setTitleColor(.white, for: .normal)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    @IBAction func addButtonTapped(_ sender: UIButton) {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let addVC = storyboard.instantiateViewController(withIdentifier: "AddTaskViewController") as? AddTaskViewController {
                addVC.modalPresentationStyle = .formSheet
                addVC.delegate = self
                present(addVC, animated: true)
            }
        }
    
    func toggleTask(id: UUID) {
        TaskManager.shared.toggleTask(id: id)

        NotificationCenter.default.post(
            name: .taskCompleted,
            object: id
        )
    }
}
extension TaskListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func didAddTask(_ task: Task) {
        print("didAddTask called:", task)
        taskManager.addTask(task)
        let tasks = TaskManager.shared.dailyPuzzle.tasks
        if !tasks.isEmpty {
            // タスク追加後は「進捗画像」を作り直してカレンダーに反映する
            let image = makePuzzleProgressImage(tasks: tasks, size: 300)
            if let data = image.pngData() {
                TaskManager.shared.dailyPuzzle.imageData = data
                TaskManager.shared.save()
                NotificationCenter.default.post(name: .puzzleImageUpdated, object: nil)
            }
        }
        tableView.reloadData()
    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        TaskManager.shared.dailyPuzzle.tasks.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell") ??
                   UITableViewCell(style: .subtitle, reuseIdentifier: "TaskCell")
        
        let task = TaskManager.shared.dailyPuzzle.tasks[indexPath.row]
        
        if cell.viewWithTag(100) == nil {
            let checkmark = UIImageView()
            checkmark.tag = 100
            checkmark.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(checkmark)
            
            NSLayoutConstraint.activate([
                checkmark.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                checkmark.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                checkmark.widthAnchor.constraint(equalToConstant: 18),
                checkmark.heightAnchor.constraint(equalToConstant: 18)
            ])
        }
        
        if let checkmark = cell.viewWithTag(100) as? UIImageView {
            if task.isDone {
                checkmark.image = UIImage(systemName: "checkmark")
                checkmark.tintColor = .magenta
            } else {
                checkmark.image = nil
            }
        }
        
        if task.isDone {
            cell.textLabel?.attributedText = NSAttributedString(
                string: task.title,
                attributes: [ .strikethroughStyle: NSUnderlineStyle.single.rawValue, // 線のスタイル
                              .strikethroughColor: UIColor.black
                ]
            )
        } else {
            cell.textLabel?.attributedText = nil
            cell.textLabel?.text = task.title
        }
        
        cell.indentationLevel = 2
        cell.indentationWidth = 18
        cell.textLabel?.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        cell.accessoryType = .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let task = taskManager.dailyPuzzle.tasks[indexPath.row]
        taskManager.toggleTask(id: task.id)

        // タスク完了通知
        NotificationCenter.default.post(
            name: .taskCompleted,
            object: task.id
        )

        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}
