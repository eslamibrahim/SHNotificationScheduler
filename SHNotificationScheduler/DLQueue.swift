//
//  DLQueue.swift
//  SHNotificationScheduler
//
//  Created by islam on 20/07/2022.
//

@available(iOS 10.0, *)
public class DLQueue: NSObject {
    
    var notifQueue = [DLNotification]()
    static let queue = DLQueue()
    
    override init() {
        super.init()
        if let notificationQueue = self.load() {
            notifQueue = notificationQueue
        }
    }
    
    internal func push(_ notification: DLNotification) {
        let concurrentQueue = DispatchQueue(label: "notifQueue.concurrent.queue", attributes: .concurrent)
        concurrentQueue.sync { [weak self] in
            let index =  self?.notifQueue.insertionIndexOf(notification) { $0.fireDate!.timeIntervalSince1970 < $1.fireDate!.timeIntervalSince1970}
            self?.notifQueue.insert(notification, at: index ?? 0)
        }
    }
    ///Removes and returns the head of the queue.
    
    internal func pop() -> DLNotification {
        return notifQueue.removeFirst()
    }
    
    //Returns the head of the queue.
    
    internal func peek() -> DLNotification? {
        return notifQueue.last 
    }
    
    ///Clears the queue.
    
    internal func clear() {
        notifQueue.removeAll()
    }
    
    ///Called when a DLLocalnotification is cancelled.
    
    internal func removeAtIndex(_ index: Int) {
        notifQueue.remove(at: index)
    }
    
    // Returns Count of DLNotifications in the queue.
    internal func count() -> Int {
        return notifQueue.count
    }
    
    // Returns The notifications queue.
    internal func notificationsQueue() -> [DLNotification] {
        let queue = notifQueue
        return queue
    }
    
    // Returns DLLocalnotifcation if found, nil otherwise.
    internal func notificationWithIdentifier(_ identifier: String) -> DLNotification? {
        for note in notifQueue {
            if note.identifier == identifier {
                return note
            }
        }
        return nil
    }
    
    
    ///Save queue on disk.
    
    internal func save() -> Bool {
        if let dLNotificationString = self.notifQueue.toString() {
            UserDefaults.standard.set(dLNotificationString, forKey: "notifications.dlqueue")
            UserDefaults.standard.synchronize()
            return true
        }else {
            return false
        }
    }
    
    ///Load queue from disk.
    ///Called first when instantiating the DLQueue singleton.
    ///You do not need to manually call this method
    
    internal func load() -> [DLNotification]? {
        let dLNotificationString = UserDefaults.standard.object(forKey: "notifications.dlqueue") as? String
        if let items : [DLNotification] = dLNotificationString?.toObject(){
            return items
        } else {
            return nil
        }
    }
    
}


extension Array {
    func insertionIndexOf(_ elem: Element, isOrderedBefore: (Element, Element) -> Bool) -> Int {
        var lo = 0
        var hi = self.count - 1
        while lo <= hi {
            let mid = (lo + hi)/2
            if isOrderedBefore(self[mid], elem) {
                lo = mid + 1
            } else if isOrderedBefore(elem, self[mid]) {
                hi = mid - 1
            } else {
                return mid // found at position mid
            }
        }
        return lo // not found, would be inserted at position lo
    }
}
extension Encodable {
 
    func toString() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let jsonData = try encoder.encode(self)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
        }
        catch {
            print(error.localizedDescription)
        }
        return nil
    }
}

extension String {
    func toObject<T: Decodable>() -> T? {
        do {
            let decoder = JSONDecoder()
            let jsonData = self.data(using: .utf8)!
            let parsedData = try decoder.decode(T.self, from: jsonData)
            return parsedData
        }
        catch {
            print(error)
        }
        return nil
    }
}
