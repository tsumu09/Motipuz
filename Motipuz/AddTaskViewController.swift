//
//  AddTaskViewController.swift
//  Motipuz
//
//  Created by 高橋紬季 on 2025/10/29.
//

import UIKit

protocol AddTaskDelegate: AnyObject {
    func didAddTask(_ task: Task)
}

class AddTaskViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var taskTitleField: UITextField!
    @IBOutlet weak var importanceSegment: UISegmentedControl!
    @IBOutlet weak var weightField: UITextField!
    @IBOutlet weak var addButton: UIButton!
    
    weak var delegate: AddTaskDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "タスク追加"
        setupUI()
    }
    
    private func setupUI() {
        addButton.setTitle("追加", for: .normal)
        //        addButton.backgroundColor = .magenta
        //        addButton.tintColor = .white
        addButton.layer.cornerRadius = 8
        
        taskTitleField.placeholder = "タスク名を入力"
        weightField.placeholder = "重さ（1〜10）"
        weightField.keyboardType = .numberPad
        weightField.delegate = self
    }
    
    @IBAction func addButtonTapped(_ sender: UIButton) {
        guard let title = taskTitleField.text, !title.isEmpty else {
            showAlert(message: "タスク名を入力してください")
            return
        }
        
        guard let weightText = weightField.text,
              let weight = Int(weightText),
              (1...10).contains(weight) else {
            showAlert(message: "重さは1〜10で入力してください")
            return
        }
        
        let importance = importanceSegment.selectedSegmentIndex + 1
        
        let task = Task(
            id: UUID(),
            title: title,
            importance: importance,
            weight: weight,
            isDone: false,
            isPlaced: false
        )
        print("delegate:", delegate as Any)
        
        delegate?.didAddTask(task)
        dismiss(animated: true)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(
            title: "入力エラー",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
