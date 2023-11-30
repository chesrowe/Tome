/// @category testing
/// @title Test system
/// @text A description of the system
///
/// - one
/// - two
/// - three

/// @func tester(x, y)
/// @desc This is a description of the function.
/// @param {real} x This is a description of this parameter
/// @param {real} y Another description
/// @return {real} The sum of `x` and `y`
function tester(x, y){
 return x + y;
}

/// @constructor
/// @func testConstructor(foo)
/// @desc A test constructor
/// @param {string} foo Does nothing
function testConstructor(foo) constructor {
    testVar = foo;
   
    /// @method testMethod(bar)
    /// @desc A test method
    /// @param {real} bar For testing 
    /// @return {real} Returns the value of bar
    testMethod = function(bar){
        return bar;
    }
}

/// @func tester2(x)
/// @desc This is a description of the function.
/// @param {real} x This is a description of this parameter
/// @return {real} `x` squared
function tester2(x, y){
    return x * x;
}