//
//  SceneDelegate.swift
//  Motipuz
//
//  Created by 高橋紬季 on 2025/10/15.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if UserDefaults.standard.object(forKey: "dailyGoalValue") == nil {
            // 初回起動 → 初期設定画面
            let goalSetupVC = storyboard.instantiateViewController(withIdentifier: "GoalSetupViewController")
            window.rootViewController = goalSetupVC
        } else {
            // 通常起動 → タスク一覧画面
            let taskListVC = storyboard.instantiateViewController(withIdentifier: "TaskListViewController")
            let nav = UINavigationController(rootViewController: taskListVC)
            window.rootViewController = nav
        }
        
        self.window = window
        window.makeKeyAndVisible()
    }


}

