//
//  GoalSetupViewController.swift
//  Motipuz
//
//  Created by 高橋紬季 on 2025/10/29.
//

import UIKit

class GoalSetupViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var goalTextField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        goalTextField.keyboardType = .numberPad
        goalTextField.delegate = self
        
        saveButton.layer.cornerRadius = 10
    }
    
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        guard let text = goalTextField.text, let goalValue = Int(text), goalValue > 0 else {
            // 入力が不正な場合はアラート
            let alert = UIAlertController(title: "エラー", message: "正しい数値を入力してください", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        UserDefaults.standard.set(goalValue, forKey: "dailyGoalValue")
        
        // タスク一覧画面に遷移
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let TaskListViewController = storyboard.instantiateViewController(withIdentifier: "TaskListViewController") as? TaskListViewController {
            let nav = UINavigationController(rootViewController: TaskListViewController)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
    }
    
    // キーボードを閉じる処理
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
