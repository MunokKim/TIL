//
//  NotificationModel.swift
//  HowlTalk
//
//  Created by 김문옥 on 2018. 4. 14..
//  Copyright © 2018년 김문옥. All rights reserved.
//

import ObjectMapper

class NotificationModel: Mappable {
    
    public var to: String?
    public var notification: Notification = Notification()
    public var data: Data = Data()
    
    init() {
        
    }
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        to <- map["to"]
        notification <- map["notification"]
        data <- map["data"]
    }
    
    class Notification: Mappable {
        
        public var title: String?
        public var text: String?
        
        init() {
            
        }
        
        required init?(map: Map) {
            
        }
        
        func mapping(map: Map) {
            
            title <- map["title"]
            text <- map["text"]
        }
    }
    
    class Data: Mappable {
        
        public var title: String?
        public var text: String?
        
        init() {
            
        }
        
        required init?(map: Map) {
            
        }
        
        func mapping(map: Map) {
            
            title <- map["title"]
            text <- map["text"]
        }
    }

}
