//
//  SceneDelegate.swift
//  Motipuz
//
//  Created by 高橋紬季 on 2025/10/15.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if UserDefaults.standard.object(forKey: "dailyGoalValue") == nil {
            // 初回起動 → 初期設定画面
            let goalSetupVC = storyboard.instantiateViewController(withIdentifier: "GoalSetupViewController")
            window.rootViewController = goalSetupVC
        } else {
            // 通常起動 → タブバー構成
            let tabBarVC = UITabBarController()
            
            // タスク一覧
            let taskListVC = storyboard.instantiateViewController(withIdentifier: "TaskListViewController")
            let nav1 = UINavigationController(rootViewController: taskListVC)
            nav1.tabBarItem = UITabBarItem(title: "タスク", image: UIImage(systemName: "checklist"), tag: 0)

            // パズル画面
            let puzzleVC = storyboard.instantiateViewController(withIdentifier: "PuzzleViewController")
            let nav2 = UINavigationController(rootViewController: puzzleVC)
            nav2.tabBarItem = UITabBarItem(title: "パズル", image: UIImage(systemName: "square.grid.3x3"), tag: 1)

            // カレンダー画面
            let calendarVC = storyboard.instantiateViewController(withIdentifier: "CalendarViewController")
            let nav3 = UINavigationController(rootViewController: calendarVC)
            nav3.tabBarItem = UITabBarItem(title: "カレンダー", image: UIImage(systemName: "calendar"), tag: 2)

            
            // タブバーに追加
            tabBarVC.viewControllers = [nav1, nav2, nav3]
            
            window.rootViewController = tabBarVC
        }
        
        self.window = window
        window.makeKeyAndVisible()
    }
}
