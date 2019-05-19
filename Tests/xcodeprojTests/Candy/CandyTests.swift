//
//  CandyTests.swift
//  XcodeProjTests
//
//  Created by apple on 2019/5/18.
//

import Foundation
import PathKit
import XCTest
@testable import XcodeProj

class CandyTests: XCTestCase {
    func test_addGroup() {
//        print(iosProjectDictionary())
        
        let iosProject = iosProjectDictionary().0
        let components = iosProject.components.dropLast()
        let path = Path(components: components)
        do {
            let candy = try Candy(path: path)
            
            let groups = try candy.addGroup("ABCD")
            XCTAssert(!groups.isEmpty)
            
            let fileGroup = groups.last!
            
            let fileStructs = multipleTestFiles()
            for fileStruct in fileStructs {
                let file = try candy.addFile(at: fileGroup, fileName: fileStruct.0, contents: fileStruct.1)
                
                _ = try candy.addBuildPhase(with: file)
            }
            
            try candy.write()
        } catch {
            print("error: \(error)")
            XCTFail()
        }
    }
}

extension CandyTests {
    typealias FileStruct = (String, Data?)
    
    func multipleTestFiles() -> [FileStruct] {
        let template = """
            import UIKit

            class EFGHViewController: UIViewController {
                override func viewDidLoad() {
                    super.viewDidLoad()
                    // Do any additional setup after loading the view, typically from a nib.
                }

                override func didReceiveMemoryWarning() {
                    super.didReceiveMemoryWarning()
                    // Dispose of any resources that can be recreated.
                }
            }
            """
        let filenames = [
            "EFGH.swift",
            "IJKL.swift",
            "MNOP.swift",
            "QRST.swift",
            "UVWX.swift"
        ]
        
        let fileStructs = filenames.map { (name) -> FileStruct in
            let string = template.replacingOccurrences(of: "EFGHViewController", with: "\(name.components(separatedBy: ".").first!)ViewController")
            let contents = string.data(using: .utf8)
            return (name, contents)
        }
        
        return fileStructs
    }
}
