//
//  TaskManager.swift
//  Motipuz
//
//  Created by 高橋紬季 on 2025/10/15.
//

import Foundation

final class TaskManager {
    static let shared = TaskManager()
    private init() {}
    
    var dailyPuzzle: DailyPuzzle = TaskManager.loadTodayPuzzle()
    
    var totalValue: Int {
        dailyPuzzle.tasks.map { $0.value }.reduce(0, +)
    }
    
    var completedValue: Int {
        dailyPuzzle.tasks.filter { $0.isDone }.map { $0.value }.reduce(0, +)
    }
    
    
    
    var gridSize: Int {
        switch totalValue {
        case 0..<50: return 3
        case 50..<100: return 4
        default: return 5
        }
    }
    
    func addTask(_ task: Task) {
        dailyPuzzle.tasks.append(task)
        save()
    }
    
    func toggleTask(id: UUID) {
        if let index = dailyPuzzle.tasks.firstIndex(where: { $0.id == id }) {
            dailyPuzzle.tasks[index].isDone.toggle()
            save()
        }
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(dailyPuzzle) {
            UserDefaults.standard.set(data, forKey: "todayPuzzle")
        }
    }
    
    var goalValue: Int {
        get {
            UserDefaults.standard.integer(forKey: "dailyGoalValue") // なければ0
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "dailyGoalValue")
        }
    }

    
    static func loadTodayPuzzle() -> DailyPuzzle {
        let today = Calendar.current.startOfDay(for: Date())
        let goal = UserDefaults.standard.integer(forKey: "dailyGoalValue")
        
        if let data = UserDefaults.standard.data(forKey: "todayPuzzle"),
           let loaded = try? JSONDecoder().decode(DailyPuzzle.self, from: data),
           Calendar.current.isDate(loaded.date, inSameDayAs: today) {
            return loaded
        }
        
        // goalValueが0の場合は初期値100を使う
        return DailyPuzzle(date: today, goalValue: goal > 0 ? goal : 100, tasks: [], imageData: nil)
    }


}

