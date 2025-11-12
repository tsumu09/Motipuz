//
//  TaskListViewController.swift
//  Motipuz
//
//  Created by 高橋紬季 on 2025/10/15.
//

import UIKit

class TaskListViewController: UIViewController {
    
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addButton: UIButton!
    
    private let taskManager = TaskManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                            target: self,
                                                            action: #selector(addButtonTapped))
        setupTableView()
      
        
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
        tableView.reloadData() // ここで最新のタスクを反映
    }

    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    
    
    
    
    
    @IBAction func addButtonTapped(_ sender: UIButton) {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let addVC = storyboard.instantiateViewController(withIdentifier: "TaskAddViewController") as? TaskAddViewController {
                addVC.modalPresentationStyle = .formSheet
                present(addVC, animated: true)
            }
        }
}
extension TaskListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        taskManager.dailyPuzzle.tasks.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell") ??
                   UITableViewCell(style: .subtitle, reuseIdentifier: "TaskCell")
        
        let task = taskManager.dailyPuzzle.tasks[indexPath.row]
        
        // ✅ チェックマーク（左側）
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
                checkmark.tintColor = .systemBlue
            } else {
                checkmark.image = nil
            }
        }
        
        if task.isDone {
                let attributedText = NSAttributedString(
                    string: task.title,
                    attributes: [
                        .strikethroughStyle: NSUnderlineStyle.single.rawValue
                    ]
                )
                cell.textLabel?.attributedText = attributedText
            } else {
                cell.textLabel?.attributedText = nil
                cell.textLabel?.text = title
            }
        
        // ✅ テキストの位置調整（チェックと重ならないように）
        cell.indentationLevel = 2
        cell.indentationWidth = 18
        
        cell.textLabel?.text = task.title
        cell.textLabel?.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        
        // アクセサリは使わない
        cell.accessoryType = .none
        
        return cell
    }


    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let task = taskManager.dailyPuzzle.tasks[indexPath.row]
        taskManager.toggleTask(id: task.id)
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}
