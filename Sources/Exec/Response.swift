//
//  Response.swift
//  Exec
//
//  Created by Jake Heiser on 9/5/17.
//

import Regex

public protocol AnyResponseGenerator {
    func matches(_ line: String) -> Bool
    func generateResponse(to line: String) -> AnyResponse
}

public class ResponseGenerator<T: Response>: AnyResponseGenerator {
    
    private let regex: Regex
    private let generate: (_ match: T.Match) -> T
    
    public init(matcher: Regex, generate: @escaping (_ match: T.Match) -> T) {
        self.regex = matcher
        self.generate = generate
    }
    
    public init(matcher: StaticString, generate: @escaping (_ match: T.Match) -> T) {
        self.regex = Regex(matcher)
        self.generate = generate
    }
    
    public func matches(_ line: String) -> Bool {
        return regex.matches(line)
    }
    
    func match(in line: String) -> T.Match? {
        guard let match = regex.firstMatch(in: line) else {
            return nil
        }
        let captures = Captures(captures: match.captures)
        return T.Match(captures: captures)
    }
    
    public func generateResponse(to line: String) -> AnyResponse {
        guard let result = match(in: line) else {
            fatalError("generateResponse should only be called if a match is guaranteed")
        }
        return generate(result)
    }
}

public protocol AnyResponse: class {
    func go()
    func keepGoing(on line: String) -> Bool
    func stop()
}

public protocol Response: AnyResponse {
    associatedtype Match: RegexMatch
}

public protocol SimpleResponse: Response {
    init(match: Match)
}

public typealias CaptureTranslation<T: RegexMatch> = (_ match: T) -> String

public class ReplaceResponse<T: RegexMatch>: Response {
    
    public typealias Match = T
    public typealias Translation = CaptureTranslation<T>
    
    public let match: T
    private let stream: StdStream
    private let translation: Translation
    
    init(match: T, stream: StdStream, translation: @escaping Translation) {
        self.match = match
        self.stream = stream
        self.translation = translation
    }
    
    public func go() {
        stream.output(translation(match))
    }
    
    public func keepGoing(on line: String) -> Bool {
        return false
    }
    
    public func stop() {}
    
}

public class IgnoreResponse: Response {
    public typealias Match = RegexMatch
    public func go() {}
    public func keepGoing(on line: String) -> Bool { return false }
    public func stop() {}
}