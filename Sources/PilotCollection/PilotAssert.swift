//
//  File.swift
//  
//
//  Created by cl d on 2022/7/23.
//

import Foundation

func PilotAssert(condition: Bool, message: String) {
    
    assert(condition, message)
    
}

func PilotParamterAssert(condition: Bool) {
    PilotAssert(condition: condition, message: "Invalid parameter not satisfying: \(condition)")
}


func PilotAssertMainThread() {
    PilotAssert(condition: Thread.isMainThread == true, message: "Must be on the main thread")
}
