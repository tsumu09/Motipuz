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
    
    func getTasks() -> [Task] {
        return dailyPuzzle.tasks
    }
    
    func toggleTask(id: UUID) {
        if let index = dailyPuzzle.tasks.firstIndex(where: { $0.id == id }) {
            dailyPuzzle.tasks[index].isDone.toggle()
            if !dailyPuzzle.tasks[index].isDone {
                dailyPuzzle.tasks[index].isPlaced = false
            }
            save()
        }
    }
    
    static func key(from date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: date)
        }
    
    func save() {
            let key = TaskManager.key(from: dailyPuzzle.date)
            if let data = try? JSONEncoder().encode(dailyPuzzle) {
                UserDefaults.standard.set(data, forKey: key)
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
            let key = key(from: today)

            if let data = UserDefaults.standard.data(forKey: key),
               let puzzle = try? JSONDecoder().decode(DailyPuzzle.self, from: data) {
                return puzzle
            }

            return DailyPuzzle(
                date: today,
                tasks: [],
                imageData: nil
            )
        }

    
    static func loadPuzzle(for date: Date) -> DailyPuzzle {
            let key = key(from: date)

            if let data = UserDefaults.standard.data(forKey: key),
               let puzzle = try? JSONDecoder().decode(DailyPuzzle.self, from: data) {
                return puzzle
            }

            return DailyPuzzle(
                date: date,
                tasks: [],
                imageData: nil
            )
        }
    func markPlaced(taskID: UUID) {
        if let index = dailyPuzzle.tasks.firstIndex(where: { $0.id == taskID }) {
            dailyPuzzle.tasks[index].isPlaced = true
            save()
        }
    }
    }
