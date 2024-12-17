//
//  Match.swift
//  Take Medication
//
//  Created by Pieter Yoshua Natanael on 06/12/24.
//





//public enum AlreadyHatchedError: Error {
//    case alreadyHatched
//}
//
//public protocol Reptile {
//    func lay() -> ReptileEgg
//}
//
//public class FireDragon : Reptile {
//    public func lay() -> ReptileEgg {
//        return ReptileEgg(createReptile: {FireDragon()})
//    }
//}
//
//public class ReptileEgg {
//    private let createReptile: () -> Reptile
//    private var hasHatched = false
//    
//    public init(createReptile: @escaping () -> Reptile) {
//        self.createReptile = createReptile
//    }
//
//    public func hatch() throws -> Reptile {
//        guard !hasHatched else {
//        throw AlreadyHatchedError.alreadyHatched
//    }
//    hasHatched = true
//    return createReptile()
//}
//}
//
//#if !RunTests
//
//let fireDragon = FireDragon()
//print(fireDragon)
//
//#endif

//public class LazyMatcher {
//    // ... existing code ...
//    
//    public func addPartialMatch(partialMatch: String) -> Void {
//        let closure = { [weak self] in
//            return self?.target.contains(partialMatch)
//        }
//        
//        self.functions.append(closure)
//    }
//    
//    // ... existing code ...
//}
