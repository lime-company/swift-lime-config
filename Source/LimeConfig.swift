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
    func load(fromDictionary: [String:Any]) -> Bool
}


public class LimeConfig {
    
    public static let shared = LimeSharedConfig.sharedConfig()
    
    public lazy var configRegister: DomainsRegister = {
        return DomainsRegister(self)
    }()
    
    fileprivate var immutableConfigs = [String:ImmutableConfig]()
    
    fileprivate let lock = LimeCore.Lock()
    
    fileprivate init() {
    }
}

// MARK: - LimeConfig singleton

internal class LimeSharedConfig: NSObject {
    
    internal static func sharedConfig() -> LimeConfig {
        let cfg = LimeConfig()
        
        // Try to access class selector +configurationForSharedInstance
        if (self as AnyClass).responds(to: NSSelectorFromString("registerConfigDomains:")) {
            // This is fun. Normally, #selector(registerConfigDomains:) swift syntax doesn't work,
            // because the compiler is not able to resolve selector which is not implemented in the code yet.
            // This may be implemented in your extension, but we don't know this information in the time of compilation.
            // So, the interesting part is, that it is still "safe" to call `configurationForSharedInstance` with
            // no warning or error :)
            (self as AnyClass).registerConfigDomains(cfg.configRegister)
        } else {
            // Print error
            D.print("LimeConfig: Error: Selector  .")
        }
        return cfg
    }
}


@objc public protocol LimeSharedConfigProvider {
    /// The method must return a valid configuration, which will be used for
    /// LocalizationProvider.shared instance setup.
    @objc static func registerConfigDomains(_ register: LimeConfig.DomainsRegister) -> Void
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
    
    public class DomainsRegister: NSObject {
        
        fileprivate unowned var config: LimeConfig
        
        private var initialRegistration: Bool
        private var mutableConfigs = [String:MutableConfig]()
        
        internal init(_ config: LimeConfig) {
            self.config = config
            self.initialRegistration = true
        }
        
        public func contains(domain: String) -> Bool {
            return config.lock.synchronized { () -> Bool in
                return self.mutableConfigs[domain] != nil
            }
        }
        
        public func register<MT: MutableConfig>(_ mutableObject: MT, for domain: String) -> MT {
            return config.lock.synchronized { () -> MT in
                if self.initialRegistration == false {
                    D.print("LimeConfig: Error: Domain '\(domain)' cannot be registered.")
                    return mutableObject
                }
                if let cfg = self.mutableConfigs[domain] {
                    if let typedCfg = cfg as? MT {
                        return typedCfg
                    }
                    D.print("LimeConfig: Error: Domain '\(domain)' has already registered mutable object.")
                }
                self.mutableConfigs[domain] = mutableObject
                return mutableObject
            }
        }
        
        public func update<MT: MutableConfig>(_ mutableObject: MT, for domain: String) {
            
        }
        
        internal func closeInitialRegistration() {
            config.lock.synchronized {
                self.initialRegistration = false
                config.immutableConfigs = self.mutableConfigs.mapValues { $0.makeImmutable() }
            }
        }
    }
}
