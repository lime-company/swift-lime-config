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

/// The `LimeSharedConfig` protocol defines class method which provides
/// configuration for shared instance of LimeConfig. You can extend
/// the LimeConfig and implement registration for all your configuration
/// domains.
///
/// Example:
/// ```
/// extension LimeConfig: LimeSharedConfig {
///     @objc public static func registerConfigDomains(_ config: LimeConfig)  {
///         MyUIConfig * uiConfig = config.register(MyUIConfig(), for: "ui")
///         uiConfig.globalBackground = UIColor.red
///     }
/// }
/// ```
@objc public protocol LimeSharedConfig {
    /// The method is called once per application's lifetime and gives you
    /// opportunity to register your own domains to LimeConfig.
    @objc static func registerConfigDomains(_ config: LimeConfig) -> Void
}

public extension LimeConfig {
    
    /// Returns the shared default object.
    ///
    /// You have to implement `LimeSharedConfig`
    public static let shared = LimeConfig.sharedConfig()
    
    internal static func sharedConfig() -> LimeConfig {
        // Create shared config
        let config = LimeConfig()
        // Try to access class selector +configurationForSharedInstance
        if (self as AnyClass).responds(to: NSSelectorFromString("registerConfigDomains:")) {
            // This is fun. Normally, #selector(registerConfigDomains:) swift syntax doesn't work,
            // because the compiler is not able to resolve selector which is not implemented in the library's code yet.
            // This may be implemented in your extension, but we don't know this information in the time of compilation.
            // So, the interesting part is, that it is still "safe" to call `registerConfigDomains:` with
            // no warning or error :)
            (self as AnyClass).registerConfigDomains(config)
        } else {
            D.print("LimeConfig: Error: Selector '+registerConfigDomains:' providing shared configuration is not implemented.")
        }
        // Close registration...
        config.closeInitialRegistration()
        return config
    }
    
}
