//
// Copyright 2018 Lime - HighTech Solutions s.r.o.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions
// and limitations under the License.
//

import Foundation
import LimeCore

internal typealias D = LimeDebug


public protocol ImmutableConfig {
}

public protocol MutableConfig {
    func makeImmutable() -> ImmutableConfig
}


public class LimeConfig: NSObject {

    let lock = LimeCore.Lock()

    var immutableConfigs = [String:ImmutableConfig]()
    
    var mutableConfigs = [String:MutableConfig]()

    var initialRegistration = false
    
    internal override init() {
    }
}

// MARK: - Immutable access -

public extension LimeConfig {
    
    public func config<T: ImmutableConfig>(for domain: String) -> T? {
        return lock.synchronized { () -> T? in
            if let c = self.immutableConfigs[domain] as? T {
                return c;
            }
            D.print("LimeConfig: Domain '\(domain)' is not registered.")
            return nil
        }
    }
}



// MARK: - Mutable access -

public extension LimeConfig {

    public func contains(domain: String) -> Bool {
        return lock.synchronized { () -> Bool in
            return self.mutableConfigs[domain] != nil
        }
    }
    
    public func register<MT: MutableConfig>(_ mutableObject: MT, for domain: String) -> MT? {
        return lock.synchronized { () -> MT? in
            if self.initialRegistration == false {
                D.print("LimeConfig: Error: Cannot register additional domain '\(domain)'.")
                return nil
            }
            if let cfg = self.mutableConfigs[domain] {
                if let typedCfg = cfg as? MT {
                    // You don't need to register the same config for twice
                    D.print("LimeConfig: Warning: Domain '\(domain)' is already registered for this type.")
                    return typedCfg
                }
                D.print("LimeConfig: Error: Domain '\(domain)' is already registered for another object type.")
                return nil
            }
            self.mutableConfigs[domain] = mutableObject
            return mutableObject
        }
    }
    
    public func update<MT: MutableConfig>(domain: String, updateBlock: (MT)->Void) {
        lock.synchronized { () in
            if let config = self.mutableConfigs[domain] as? MT {
                updateBlock(config)
                self.immutableConfigs[domain] = config.makeImmutable()
            } else {
                D.print("LimeConfig: Domain '\(domain)' is not registered and therefore cannot be updated.")
            }
        }
    }
    
    internal func closeInitialRegistration() {
        lock.synchronized {
            self.initialRegistration = false
            self.immutableConfigs = self.mutableConfigs.mapValues { $0.makeImmutable() }
        }
    }
}
