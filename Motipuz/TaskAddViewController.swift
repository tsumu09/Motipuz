//
//  TaskAddViewController.swift
//  Motipuz
//
//  Created by 高橋紬季 on 2025/10/29.
//

import UIKit

class TaskAddViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var taskTitleField: UITextField!
    @IBOutlet weak var importanceSegment: UISegmentedControl!
    @IBOutlet weak var weightField: UITextField!
    @IBOutlet weak var addButton: UIButton!
    
    private let taskManager = TaskManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "タスク追加"
        setupUI()
    }
    
    private func setupUI() {
        addButton.setTitle("追加", for: .normal)
        addButton.backgroundColor = .systemBlue
        addButton.tintColor = .white
        addButton.layer.cornerRadius = 8
        
        taskTitleField.placeholder = "タスク名を入力"
        weightField.placeholder = "重さ（1〜10）"
        weightField.keyboardType = .numberPad
        weightField.delegate = self
    }
    
    @IBAction func addButtonTapped(_ sender: UIButton) {
        guard let title = taskTitleField.text, !title.isEmpty,
              let weightText = weightField.text, let weight = Int(weightText) else {
            let alert = UIAlertController(title: "エラー", message: "正しいタスク名と重さを入力してください", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        // 重要度は Segment で選択した値を取得
        let importance = importanceSegment.selectedSegmentIndex + 1
        
        let newTask = Task(title: title, importance: importance, weight: weight, isDone: false)
        
        // TaskManager に追加
        TaskManager.shared.addTask(newTask)

        // TaskListViewController に戻る
        dismiss(animated: true)
    }

    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "入力エラー", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
