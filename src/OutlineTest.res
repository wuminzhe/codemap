open Index

// Test the getOutlineAsync function with the test.py file
let testOutlineAsync = () => {
  Console.log("Testing getOutlineAsync with test.py...")
  
  getOutlineAsync("./test.py")
  ->Promise.then(result => {
    switch result {
    | Ok(outline) => {
        Console.log("Successfully generated outline:")
        Console.log(outline)
      }
    | Error(err) => {
        Console.log("Failed to generate outline:")
        Console.log(err)
      }
    }
    Promise.resolve()
  })
  ->Promise.catch(_ => {
    Console.log("Error during outline generation")
    Promise.resolve()
  })
}

// Run the test
let _ = testOutlineAsync()
