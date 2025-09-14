# 🎓 C Programming Complete Tutorial 
## MJBC111

![C](https://img.shields.io/badge/C-00599C?style=for-the-badge&logo=c&logoColor=white)
![Lines of Code](https://img.shields.io/badge/Lines%20of%20Code-10000+-blue?style=for-the-badge)
![Progress](https://img.shields.io/badge/Progress-100%25-brightgreen?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)
![Contributions](https://img.shields.io/badge/Contributions-Welcome-orange?style=for-the-badge)
![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20Windows%20%7C%20Mac-lightgrey?style=for-the-badge)

## 📚 Welcome to C Programming

This comprehensive tutorial covers all topics in the MJBC111 C Programming course. Each section includes detailed theory, syntax explanations, examples, and exercises - structured like W3Schools for easy learning.

### 🎯 Course Learning Outcomes

✅ **CO1:** Master the fundamental concepts of C programming  
✅ **CO2:** Apply logical problem-solving techniques using C  
✅ **CO3:** Implement modular programming using functions  
✅ **CO4:** Design and utilize structures and unions effectively  
✅ **CO5:** Understand memory management and file handling  

---

## 📋 Course Contents

### [Unit 1: Overview of C](#-what-is-c-programming)
### [Unit 2: Constants, Variables & Data Types](#-data-types-in-c)
### [Unit 3: If-else, else-if and Switch-case](#-introduction-to-decision-making)
### [Unit 4: Loops for, while, do-while, ](#-introduction-to-loops)
### [Unit 5: Arrays](#-introduction-to-arrays)

---

# Unit 1: Overview of C

## 📖 What is C Programming?

C is a **general-purpose programming language** created by Dennis Ritchie at Bell Laboratories in 1972. It is one of the most widely used programming languages of all time.

### Why Learn C?

- ✅ **Foundation Language**: Most modern languages like C++, Java, and Python are influenced by C
- ✅ **System Programming**: Operating systems, embedded systems, and drivers are written in C
- ✅ **Fast and Efficient**: C provides direct hardware access and minimal runtime overhead
- ✅ **Portable**: C programs can run on different platforms with minimal changes
- ✅ **Industry Demand**: Still widely used in industries for system-level programming

### Applications of C

1. **Operating Systems** (Windows, Linux, macOS kernels)
2. **Embedded Systems** (Microcontrollers, IoT devices)
3. **System Software** (Compilers, Interpreters)
4. **Database Systems** (MySQL, PostgreSQL)
5. **Gaming Engines** (High-performance graphics)

## 🏗️ Structure of a C Program

Every C program consists of the following parts:

```
┌─────────────────────────────┐
│   Preprocessor Directives   │  ← #include, #define
├─────────────────────────────┤
│   Global Declarations       │  ← Global variables, functions
├─────────────────────────────┤
│   main() function           │  ← Program entry point
│   {                         │
│      Local Declarations     │  ← Local variables
│      Statements             │  ← Program logic
│      Return Statement       │  ← Exit status
│   }                         │
├─────────────────────────────┤
│   User-defined Functions    │  ← Additional functions
└─────────────────────────────┘
```

### Basic Syntax Rules

| Component | Rule | Example |
|-----------|------|---------|
| **Statements** | End with semicolon (;) | `printf("Hello");` |
| **Blocks** | Enclosed in curly braces {} | `{ statement1; statement2; }` |
| **Comments** | Single: // or Multi: /* */ | `// This is a comment` |
| **Case Sensitive** | C is case-sensitive | `int` ≠ `Int` ≠ `INT` |
| **Free Format** | Whitespace ignored | Can write in multiple lines |

## 💻 Your First C Program

### Example: Hello World

```c
/* 
   Program: Hello World
   Purpose: Understanding basic C program structure
   Author: Your Name
*/

#include <stdio.h>    // Step 1: Include header files

int main()           // Step 2: Main function
{                    // Step 3: Opening brace
    // Step 4: Write your code
    printf("Hello, World!\n");
    
    // Step 5: Return statement
    return 0;        // 0 indicates successful execution
}                    // Step 6: Closing brace
```

### Understanding Each Line

| Line | Purpose |
|------|---------|
| `#include <stdio.h>` | Includes Standard Input/Output library for printf() |
| `int main()` | Main function where program execution begins |
| `printf()` | Built-in function to display output |
| `\n` | Escape sequence for new line |
| `return 0` | Returns exit status to operating system |

## 🔄 Program Execution Process

### How C Program Executes

```
Source Code (.c) → Preprocessor → Compiler → Assembler → Linker → Executable
     ↓                 ↓            ↓          ↓          ↓           ↓
  program.c      Expanded Code  Assembly   Object    Linked     program.exe
                               Code(.s)   File(.o)  Program
```

### Compilation Steps Explained

1. **Preprocessing Phase**
   - Removes comments
   - Expands macros (#define)
   - Includes header files (#include)
   - Conditional compilation (#ifdef)

2. **Compilation Phase**
   - Syntax checking
   - Converts to assembly language
   - Optimizations applied

3. **Assembly Phase**
   - Converts assembly to machine code
   - Creates object file (.o or .obj)

4. **Linking Phase**
   - Links object files
   - Links library functions
   - Creates final executable

### Try It Yourself #1

```c
#include <stdio.h>

int main() {
    printf("Welcome to C Programming!\n");
    printf("Course: MJBC111\n");
    printf("Happy Learning!\n");
    return 0;
}
```

**Expected Output:**
```
Welcome to C Programming!
Course: MJBC111
Happy Learning!
```

### Common Errors and Solutions

| Error | Cause | Solution |
|-------|-------|----------|
| `stdio.h not found` | Missing header | Check #include spelling |
| `undefined reference to main` | No main function | Add int main() |
| `expected ';'` | Missing semicolon | Add ; at line end |
| `undeclared identifier` | Variable not declared | Declare before use |

---

# Unit 2: Constants, Variables and Data Types

## 📊 Data Types in C

Data types specify the type of data that a variable can store. C supports several built-in data types.

### Primary Data Types

| Data Type | Keyword | Size (bytes) | Range | Format Specifier |
|-----------|---------|--------------|-------|------------------|
| **Character** | `char` | 1 | -128 to 127 | %c |
| **Integer** | `int` | 4 | -2,147,483,648 to 2,147,483,647 | %d or %i |
| **Float** | `float` | 4 | 3.4E-38 to 3.4E+38 | %f |
| **Double** | `double` | 8 | 1.7E-308 to 1.7E+308 | %lf |
| **Void** | `void` | 0 | No value | - |

### Data Type Modifiers

Modifiers alter the size and range of basic data types:

| Modifier | Used With | Purpose |
|----------|-----------|---------|
| `short` | int | Reduces size (2 bytes) |
| `long` | int, double | Increases size |
| `signed` | int, char | Can store negative values (default) |
| `unsigned` | int, char | Only positive values |

### Modified Data Types Table

```c
// Examples of modified data types
short int a;           // 2 bytes: -32,768 to 32,767
long int b;            // 8 bytes: larger range
unsigned int c;        // 4 bytes: 0 to 4,294,967,295
unsigned char d;       // 1 byte: 0 to 255
long long int e;       // 8 bytes: very large numbers
```

## 🔢 Variables

A **variable** is a named memory location that stores data. Think of it as a container that holds values.

### Variable Declaration Syntax

```c
datatype variable_name;

// Examples
int age;              // Declares an integer variable
float salary;         // Declares a float variable
char grade;          // Declares a character variable
```

### Variable Initialization

```c
// Method 1: Declaration then Assignment
int age;
age = 25;

// Method 2: Declaration with Initialization
int age = 25;

// Method 3: Multiple declarations
int x, y, z;

// Method 4: Multiple initializations
int a = 10, b = 20, c = 30;
```

### Variable Naming Rules

✅ **MUST Follow:**
- Start with letter or underscore (_)
- Contain only letters, digits, and underscores
- Case sensitive (age ≠ Age ≠ AGE)
- Cannot use C keywords

❌ **AVOID:**
- Starting with numbers (1var)
- Special characters ($var, var@)
- Spaces (my var)
- Keywords (int, float, return)

### Good Variable Naming Practices

```c
// Good Examples
int studentAge;        // Camel case
float total_salary;    // Snake case
char GRADE;           // Constants in uppercase
int _privateVar;      // Underscore for private

// Bad Examples
int a;                // Not descriptive
int x1234;           // Meaningless
int myVariableForStoringTheAgeOfStudent;  // Too long
```

## 📌 Constants

Constants are fixed values that cannot be changed during program execution.

### Types of Constants

#### 1. Literal Constants

```c
// Integer constants
10, -50, 0x1A (hexadecimal), 077 (octal)

// Floating constants
3.14, -0.5, 2.5e3 (scientific notation)

// Character constants
'A', '5', '\n' (escape sequence)

// String constants
"Hello", "C Programming"
```

#### 2. Symbolic Constants

**Method 1: Using #define (Preprocessor)**
```c
#define PI 3.14159
#define MAX_SIZE 100
#define NEWLINE '\n'

// Usage
float area = PI * radius * radius;
```

**Method 2: Using const keyword**
```c
const int DAYS_IN_WEEK = 7;
const float GRAVITY = 9.81;
const char GRADE = 'A';

// Error: Cannot modify
// DAYS_IN_WEEK = 8;  // This will cause compilation error
```

### Escape Sequences

Special characters that represent non-printable actions:

| Escape Sequence | Meaning | Example Usage |
|-----------------|---------|---------------|
| `\n` | New line | `printf("Line 1\nLine 2");` |
| `\t` | Horizontal tab | `printf("Col1\tCol2");` |
| `\\` | Backslash | `printf("C:\\Program Files");` |
| `\"` | Double quote | `printf("He said \"Hello\"");` |
| `\'` | Single quote | `printf("It\'s C");` |
| `\0` | Null character | String terminator |
| `\b` | Backspace | Moves cursor back |
| `\r` | Carriage return | Returns to line beginning |

## ⚙️ Operators

Operators are symbols that perform operations on operands.

### 1. Arithmetic Operators

| Operator | Name | Example | Result (if a=10, b=3) |
|----------|------|---------|------------------------|
| `+` | Addition | `a + b` | 13 |
| `-` | Subtraction | `a - b` | 7 |
| `*` | Multiplication | `a * b` | 30 |
| `/` | Division | `a / b` | 3 (integer division) |
| `%` | Modulus | `a % b` | 1 (remainder) |

**Important:** Integer division truncates decimal part!

```c
int result1 = 10 / 3;      // Result: 3
float result2 = 10.0 / 3;  // Result: 3.333...
```

### 2. Relational Operators

Used to compare two values. Result is either 1 (true) or 0 (false).

| Operator | Meaning | Example | Result (if a=10, b=5) |
|----------|---------|---------|-------------------------|
| `==` | Equal to | `a == b` | 0 (false) |
| `!=` | Not equal to | `a != b` | 1 (true) |
| `>` | Greater than | `a > b` | 1 (true) |
| `<` | Less than | `a < b` | 0 (false) |
| `>=` | Greater than or equal | `a >= b` | 1 (true) |
| `<=` | Less than or equal | `a <= b` | 0 (false) |

### 3. Logical Operators

Used to combine multiple conditions:

| Operator | Name | Example | Description |
|----------|------|---------|-------------|
| `&&` | AND | `(a > 5) && (b < 10)` | True if both conditions are true |
| `\|\|` | OR | `(a > 5) \|\| (b < 10)` | True if at least one is true |
| `!` | NOT | `!(a > 5)` | Reverses the logic |

**Truth Table:**
```
A    B    A && B    A || B    !A
0    0      0         0        1
0    1      0         1        1
1    0      0         1        0
1    1      1         1        0
```

### 4. Assignment Operators

| Operator | Example | Equivalent To |
|----------|---------|---------------|
| `=` | `a = 5` | Simple assignment |
| `+=` | `a += 3` | `a = a + 3` |
| `-=` | `a -= 3` | `a = a - 3` |
| `*=` | `a *= 3` | `a = a * 3` |
| `/=` | `a /= 3` | `a = a / 3` |
| `%=` | `a %= 3` | `a = a % 3` |

### 5. Increment/Decrement Operators

| Operator | Name | Example | Effect |
|----------|------|---------|--------|
| `++a` | Pre-increment | `b = ++a` | Increment first, then use |
| `a++` | Post-increment | `b = a++` | Use first, then increment |
| `--a` | Pre-decrement | `b = --a` | Decrement first, then use |
| `a--` | Post-decrement | `b = a--` | Use first, then decrement |

**Understanding the Difference:**
```c
int a = 5, b;

// Pre-increment
b = ++a;  // a is incremented to 6, then b = 6
// Result: a = 6, b = 6

// Reset
a = 5;

// Post-increment
b = a++;  // b = 5, then a is incremented to 6
// Result: a = 6, b = 5
```

### 6. Conditional (Ternary) Operator

Syntax: `condition ? expression1 : expression2`

```c
// Traditional if-else
if (age >= 18)
    status = "Adult";
else
    status = "Minor";

// Using ternary operator
status = (age >= 18) ? "Adult" : "Minor";

// Finding maximum
int max = (a > b) ? a : b;
```

### 7. Bitwise Operators

Operate on individual bits:

| Operator | Name | Example | Description |
|----------|------|---------|-------------|
| `&` | AND | `a & b` | Bitwise AND |
| `\|` | OR | `a \| b` | Bitwise OR |
| `^` | XOR | `a ^ b` | Bitwise XOR |
| `~` | NOT | `~a` | Bitwise complement |
| `<<` | Left shift | `a << 2` | Shift bits left |
| `>>` | Right shift | `a >> 2` | Shift bits right |

## 📈 Operator Precedence

Order of evaluation (highest to lowest):

| Priority | Operators | Associativity |
|----------|-----------|---------------|
| 1 | `()` `[]` `->` `.` | Left to Right |
| 2 | `!` `~` `++` `--` `+` `-` `*` `&` `sizeof` | Right to Left |
| 3 | `*` `/` `%` | Left to Right |
| 4 | `+` `-` | Left to Right |
| 5 | `<<` `>>` | Left to Right |
| 6 | `<` `<=` `>` `>=` | Left to Right |
| 7 | `==` `!=` | Left to Right |
| 8 | `&` | Left to Right |
| 9 | `^` | Left to Right |
| 10 | `\|` | Left to Right |
| 11 | `&&` | Left to Right |
| 12 | `\|\|` | Left to Right |
| 13 | `?:` | Right to Left |
| 14 | `=` `+=` `-=` etc. | Right to Left |
| 15 | `,` | Left to Right |

## 🔄 Type Conversion

### Implicit Type Conversion (Automatic)

C automatically converts data types in expressions:

**Hierarchy:** `char` → `int` → `float` → `double`

```c
int a = 10;
float b = 5.5;
float result = a + b;  // 'a' automatically converted to float
// Result: 15.5
```

### Explicit Type Conversion (Type Casting)

Manually convert one type to another:

**Syntax:** `(datatype) expression`

```c
int a = 10, b = 3;
float result;

// Without casting
result = a / b;        // Integer division: 3.0

// With casting
result = (float)a / b; // Float division: 3.333...
```

### Complete Example: All Concepts

```c
#include <stdio.h>
#define PI 3.14159

int main() {
    // Variables and Constants
    const int MAX_MARKS = 100;
    int marks = 85;
    float percentage;
    char grade;
    
    // Arithmetic Operations
    percentage = (float)marks / MAX_MARKS * 100;
    
    // Conditional Operator
    grade = (percentage >= 90) ? 'A' : 
            (percentage >= 80) ? 'B' : 
            (percentage >= 70) ? 'C' : 
            (percentage >= 60) ? 'D' : 'F';
    
    // Display Results
    printf("=== Student Report Card ===\n");
    printf("Marks: %d/%d\n", marks, MAX_MARKS);
    printf("Percentage: %.2f%%\n", percentage);
    printf("Grade: %c\n", grade);
    
    // Relational and Logical Operators
    if (marks >= 40 && marks <= MAX_MARKS) {
        printf("Status: PASS\n");
    } else {
        printf("Status: FAIL\n");
    }
    
    // Increment/Decrement
    int bonus = 5;
    marks += bonus;  // Using compound assignment
    printf("After bonus: %d\n", marks);
    
    return 0;
}
```

---

# Unit 3: Decision Making and Branching

## 🔀 Introduction to Decision Making

Decision making structures allow programs to execute different code blocks based on conditions. C provides several decision-making statements.

### Types of Decision Making Statements

1. **Simple if statement**
2. **if-else statement**
3. **Nested if statement**
4. **else-if ladder**
5. **switch-case statement**

## 📝 The if Statement

The simplest form of decision making. Executes a block of code only if the condition is true.

### Syntax

```c
if (condition) {
    // Code to execute if condition is true
}
```

### How it Works

```
     Start
        ↓
    [Condition?]
     ↙        ↘
   True      False
    ↓          ↓
[Execute]   [Skip]
    ↓          ↓
    ↘        ↙
     Continue
```

### Example: Simple if

```c
#include <stdio.h>

int main() {
    int age = 20;
    
    // Simple if statement
    if (age >= 18) {
        printf("You are eligible to vote.\n");
        printf("Please register to vote.\n");
    }
    
    printf("Thank you!\n");  // This always executes
    return 0;
}
```

## 🔄 The if-else Statement

Provides an alternative path when the condition is false.

### Syntax

```c
if (condition) {
    // Code if condition is true
} else {
    // Code if condition is false
}
```

### Flowchart

```
       Start
          ↓
    [Condition?]
     ↙        ↘
   True      False
    ↓          ↓
[Block 1]  [Block 2]
    ↓          ↓
    ↘        ↙
     Continue
```

### Example: if-else

```c
#include <stdio.h>

int main() {
    int number;
    
    printf("Enter a number: ");
    scanf("%d", &number);
    
    // Check if number is even or odd
    if (number % 2 == 0) {
        printf("%d is an even number.\n", number);
    } else {
        printf("%d is an odd number.\n", number);
    }
    
    return 0;
}
```

## 🏗️ Nested if Statements

An if statement inside another if statement.

### Syntax

```c
if (condition1) {
    if (condition2) {
        // Code when both conditions are true
    } else {
        // Code when condition1 is true but condition2 is false
    }
} else {
    // Code when condition1 is false
}
```

### Example: Nested if

```c
#include <stdio.h>

int main() {
    int age;
    char hasLicense;
    
    printf("Enter your age: ");
    scanf("%d", &age);
    
    if (age >= 18) {
        printf("Do you have a driving license? (y/n): ");
        scanf(" %c", &hasLicense);
        
        if (hasLicense == 'y' || hasLicense == 'Y') {
            printf("You can drive a car!\n");
        } else {
            printf("You need a license to drive.\n");
        }
    } else {
        printf("You must be 18+ to drive.\n");
    }
    
    return 0;
}
```

## 🪜 The else-if Ladder

Used when multiple conditions need to be checked sequentially.

### Syntax

```c
if (condition1) {
    // Code for condition1
} else if (condition2) {
    // Code for condition2
} else if (condition3) {
    // Code for condition3
} else {
    // Default code
}
```

### Example: Grade Calculator

```c
#include <stdio.h>

int main() {
    int marks;
    char grade;
    
    printf("Enter marks (0-100): ");
    scanf("%d", &marks);
    
    // Input validation
    if (marks < 0 || marks > 100) {
        printf("Invalid marks! Please enter between 0-100.\n");
    } else if (marks >= 90) {
        grade = 'A';
        printf("Grade: %c (Outstanding!)\n", grade);
    } else if (marks >= 80) {
        grade = 'B';
        printf("Grade: %c (Excellent!)\n", grade);
    } else if (marks >= 70) {
        grade = 'C';
        printf("Grade: %c (Good!)\n", grade);
    } else if (marks >= 60) {
        grade = 'D';
        printf("Grade: %c (Average)\n", grade);
    } else if (marks >= 40) {
        grade = 'E';
        printf("Grade: %c (Pass)\n", grade);
    } else {
        grade = 'F';
        printf("Grade: %c (Fail)\n", grade);
    }
    
    return 0;
}
```

## 🎯 The switch-case Statement

Provides efficient multi-way branching based on the value of an expression.

### Syntax

```c
switch (expression) {
    case constant1:
        // Code for case 1
        break;
    case constant2:
        // Code for case 2
        break;
    case constant3:
        // Code for case 3
        break;
    default:
        // Default code
}
```

### Important Rules

1. **Expression must be integer or character** (not float/double)
2. **Case values must be constants** (not variables)
3. **break statement is important** (prevents fall-through)
4. **default is optional** (but recommended)
5. **Cases can be grouped** (multiple cases same action)

### Example: Menu-Driven Calculator

```c
#include <stdio.h>

int main() {
    char operator;
    float num1, num2, result;
    
    printf("=== Simple Calculator ===\n");
    printf("Operations: +, -, *, /, %%\n");
    printf("Enter first number: ");
    scanf("%f", &num1);
    printf("Enter operator: ");
    scanf(" %c", &operator);
    printf("Enter second number: ");
    scanf("%f", &num2);
    
    switch(operator) {
        case '+':
            result = num1 + num2;
            printf("%.2f + %.2f = %.2f\n", num1, num2, result);
            break;
            
        case '-':
            result = num1 - num2;
            printf("%.2f - %.2f = %.2f\n", num1, num2, result);
            break;
            
        case '*':
            result = num1 * num2;
            printf("%.2f * %.2f = %.2f\n", num1, num2, result);
            break;
            
        case '/':
            if (num2 != 0) {
                result = num1 / num2;
                printf("%.2f / %.2f = %.2f\n", num1, num2, result);
            } else {
                printf("Error: Division by zero!\n");
            }
            break;
            
        case '%':
            if (num2 != 0) {
                int n1 = (int)num1;
                int n2 = (int)num2;
                printf("%d %% %d = %d\n", n1, n2, n1 % n2);
            } else {
                printf("Error: Modulo by zero!\n");
            }
            break;
            
        default:
            printf("Error: Invalid operator!\n");
    }
    
    return 0;
}
```

### Example: Day of Week

```c
#include <stdio.h>

int main() {
    int day;
    
    printf("Enter day number (1-7): ");
    scanf("%d", &day);
    
    switch(day) {
        case 1:
            printf("Monday - Start of work week\n");
            break;
        case 2:
            printf("Tuesday\n");
            break;
        case 3:
            printf("Wednesday - Midweek\n");
            break;
        case 4:
            printf("Thursday\n");
            break;
        case 5:
            printf("Friday - TGIF!\n");
            break;
        case 6:
        case 7:  // Multiple cases same action
            printf("Weekend - Enjoy!\n");
            break;
        default:
            printf("Invalid day number!\n");
    }
    
    return 0;
}
```

## 🆚 if-else vs switch

| Feature | if-else | switch |
|---------|---------|---------|
| **Condition Type** | Any expression | Only integer/char |
| **Multiple Conditions** | Can use logical operators | Only equality check |
| **Floating Point** | ✅ Supported | ❌ Not supported |
| **Range Checking** | ✅ Easy | ❌ Difficult |
| **Performance** | Slower for many conditions | Faster for many cases |
| **Fall-through** | Not applicable | Possible (without break) |
| **Best For** | Complex conditions | Menu-driven programs |

## 📝 Practical Examples

### Example 1: Leap Year Checker

```c
#include <stdio.h>

int main() {
    int year;
    
    printf("Enter a year: ");
    scanf("%d", &year);
    
    // Leap year logic:
    // 1. Divisible by 400 OR
    // 2. Divisible by 4 AND NOT divisible by 100
    
    if (year % 400 == 0) {
        printf("%d is a leap year.\n", year);
    } else if (year % 100 == 0) {
        printf("%d is not a leap year.\n", year);
    } else if (year % 4 == 0) {
        printf("%d is a leap year.\n", year);
    } else {
        printf("%d is not a leap year.\n", year);
    }
    
    return 0;
}
```

### Example 2: Triangle Validator

```c
#include <stdio.h>

int main() {
    float side1, side2, side3;
    
    printf("Enter three sides of triangle: ");
    scanf("%f %f %f", &side1, &side2, &side3);
    
    // Triangle inequality theorem
    if (side1 + side2 > side3 && 
        side2 + side3 > side1 && 
        side1 + side3 > side2) {
        
        printf("Valid triangle!\n");
        
        // Check triangle type
        if (side1 == side2 && side2 == side3) {
            printf("Type: Equilateral\n");
        } else if (side1 == side2 || side2 == side3 || side1 == side3) {
            printf("Type: Isosceles\n");
        } else {
            printf("Type: Scalene\n");
        }
    } else {
        printf("Invalid triangle!\n");
    }
    
    return 0;
}
```

---

# Unit 4: Concepts of Loops

## 🔄 Introduction to Loops

Loops allow us to execute a block of code repeatedly based on a condition. They are essential for automating repetitive tasks.

### Why Use Loops?

Consider printing numbers 1 to 100:
```c
// Without loops (impractical)
printf("1\n");
printf("2\n");
printf("3\n");
// ... 97 more lines!

// With loops (efficient)
for(int i = 1; i <= 100; i++) {
    printf("%d\n", i);
}
```

### Types of Loops in C

| Loop Type | When to Use | Syntax Requirement |
|-----------|-------------|-------------------|
| **while** | When number of iterations is unknown | Condition at start |
| **do-while** | Execute at least once | Condition at end |
| **for** | When number of iterations is known | All parts in header |

## 🔁 The while Loop

Executes code block as long as the condition is true.

### Syntax

```c
initialization;
while (condition) {
    // Code to repeat
    update;
}
```

### Flowchart

```
    Start
      ↓
  Initialize
      ↓
  ┌─────────┐
  ↓         ↑
[Condition?]│
  ↓ True    │
[Execute]   │
  ↓         │
[Update]────┘
  ↓ False
  End
```

### Example: Basic while Loop

```c
#include <stdio.h>

int main() {
    // Print numbers 1 to 5
    int i = 1;  // Initialization
    
    while (i <= 5) {  // Condition
        printf("Number: %d\n", i);
        i++;  // Update
    }
    
    return 0;
}
```

### Example: Sum of Natural Numbers

```c
#include <stdio.h>

int main() {
    int n, sum = 0, i = 1;
    
    printf("Enter a positive number: ");
    scanf("%d", &n);
    
    while (i <= n) {
        sum += i;  // sum = sum + i
        i++;
    }
    
    printf("Sum of first %d natural numbers = %d\n", n, sum);
    printf("Formula verification: %d\n", n * (n + 1) / 2);
    
    return 0;
}
```

### Example: Reverse a Number

```c
#include <stdio.h>

int main() {
    int num, reversed = 0, remainder;
    
    printf("Enter a number: ");
    scanf("%d", &num);
    
    int original = num;
    
    while (num != 0) {
        remainder = num % 10;         // Get last digit
        reversed = reversed * 10 + remainder;  // Build reversed number
        num = num / 10;               // Remove last digit
    }
    
    printf("Original: %d\n", original);
    printf("Reversed: %d\n", reversed);
    
    return 0;
}
```

## 🔂 The do-while Loop

Executes code block at least once, then checks condition.

### Syntax

```c
initialization;
do {
    // Code to repeat
    update;
} while (condition);  // Note the semicolon!
```

### Key Difference from while

```c
// while: Check first, then execute
int x = 10;
while (x < 5) {
    printf("This won't print\n");
}

// do-while: Execute first, then check
int y = 10;
do {
    printf("This will print once\n");
} while (y < 5);
```

### Example: Menu-Driven Program

```c
#include <stdio.h>

int main() {
    int choice;
    int num1, num2;
    
    do {
        printf("\n=== CALCULATOR MENU ===\n");
        printf("1. Addition\n");
        printf("2. Subtraction\n");
        printf("3. Multiplication\n");
        printf("4. Division\n");
        printf("5. Exit\n");
        printf("Enter choice: ");
        scanf("%d", &choice);
        
        if (choice >= 1 && choice <= 4) {
            printf("Enter two numbers: ");
            scanf("%d %d", &num1, &num2);
        }
        
        switch(choice) {
            case 1:
                printf("Result: %d + %d = %d\n", num1, num2, num1 + num2);
                break;
            case 2:
                printf("Result: %d - %d = %d\n", num1, num2, num1 - num2);
                break;
            case 3:
                printf("Result: %d * %d = %d\n", num1, num2, num1 * num2);
                break;
            case 4:
                if (num2 != 0)
                    printf("Result: %d / %d = %.2f\n", num1, num2, (float)num1/num2);
                else
                    printf("Error: Division by zero!\n");
                break;
            case 5:
                printf("Thank you for using calculator!\n");
                break;
            default:
                printf("Invalid choice! Try again.\n");
        }
    } while (choice != 5);
    
    return 0;
}
```

## 🔁 The for Loop

Most commonly used loop when number of iterations is known.

### Syntax

```c
for (initialization; condition; update) {
    // Code to repeat
}
```

### Execution Order

1. **Initialization** (executed once)
2. **Condition check**
3. **Code block** (if condition true)
4. **Update**
5. **Go to step 2**

### Example: Basic for Loop

```c
#include <stdio.h>

int main() {
    // All three parts in header
    for (int i = 1; i <= 5; i++) {
        printf("Iteration %d\n", i);
    }
    
    // Multiple initializations and updates
    for (int i = 0, j = 10; i < 5; i++, j--) {
        printf("i = %d, j = %d\n", i, j);
    }
    
    return 0;
}
```

### Example: Multiplication Table

```c
#include <stdio.h>

int main() {
    int num;
    
    printf("Enter a number: ");
    scanf("%d", &num);
    
    printf("\nMultiplication table of %d:\n", num);
    printf("------------------------\n");
    
    for (int i = 1; i <= 10; i++) {
        printf("%2d × %2d = %3d\n", num, i, num * i);
    }
    
    return 0;
}
```

### Example: Factorial Calculation

```c
#include <stdio.h>

int main() {
    int n;
    unsigned long long factorial = 1;
    
    printf("Enter a positive integer: ");
    scanf("%d", &n);
    
    if (n < 0) {
        printf("Factorial not defined for negative numbers!\n");
    } else {
        for (int i = 1; i <= n; i++) {
            factorial *= i;
        }
        printf("%d! = %llu\n", n, factorial);
    }
    
    return 0;
}
```

## 🏗️ Nested Loops

A loop inside another loop. Used for working with 2D structures, patterns, etc.

### Syntax

```c
for (int i = 0; i < rows; i++) {      // Outer loop
    for (int j = 0; j < cols; j++) {  // Inner loop
        // Code
    }
}
```

### Example: Pattern Printing

```c
#include <stdio.h>

int main() {
    int n = 5;
    
    // Pattern 1: Right Triangle
    printf("Pattern 1: Right Triangle\n");
    for (int i = 1; i <= n; i++) {
        for (int j = 1; j <= i; j++) {
            printf("* ");
        }
        printf("\n");
    }
    
    // Pattern 2: Number Pyramid
    printf("\nPattern 2: Number Pyramid\n");
    for (int i = 1; i <= n; i++) {
        // Print spaces
        for (int j = 1; j <= n - i; j++) {
            printf("  ");
        }
        // Print numbers ascending
        for (int j = 1; j <= i; j++) {
            printf("%d ", j);
        }
        // Print numbers descending
        for (int j = i - 1; j >= 1; j--) {
            printf("%d ", j);
        }
        printf("\n");
    }
    
    // Pattern 3: Floyd's Triangle
    printf("\nPattern 3: Floyd's Triangle\n");
    int num = 1;
    for (int i = 1; i <= n; i++) {
        for (int j = 1; j <= i; j++) {
            printf("%3d ", num++);
        }
        printf("\n");
    }
    
    return 0;
}
```

## 🛑 Loop Control Statements

### 1. break Statement

Exits the loop immediately.

```c
#include <stdio.h>

int main() {
    // Find first number divisible by 7
    for (int i = 1; i <= 100; i++) {
        if (i % 7 == 0) {
            printf("First number divisible by 7: %d\n", i);
            break;  // Exit loop
        }
    }
    
    // Break in nested loops (exits only inner loop)
    for (int i = 1; i <= 3; i++) {
        for (int j = 1; j <= 3; j++) {
            if (j == 2) {
                break;  // Exits inner loop only
            }
            printf("i=%d, j=%d\n", i, j);
        }
    }
    
    return 0;
}
```

### 2. continue Statement

Skips remaining code in current iteration and moves to next iteration.

```c
#include <stdio.h>

int main() {
    // Print all numbers except multiples of 3
    printf("Numbers 1-10 (excluding multiples of 3):\n");
    for (int i = 1; i <= 10; i++) {
        if (i % 3 == 0) {
            continue;  // Skip this iteration
        }
        printf("%d ", i);
    }
    printf("\n");
    
    // Sum of positive numbers only
    int sum = 0, num;
    printf("\nEnter 5 numbers:\n");
    
    for (int i = 1; i <= 5; i++) {
        scanf("%d", &num);
        if (num < 0) {
            printf("Negative number ignored\n");
            continue;
        }
        sum += num;
    }
    printf("Sum of positive numbers: %d\n", sum);
    
    return 0;
}
```

## 🔄 Loop Comparison

### Infinite Loops

```c
// while infinite loop
while (1) {
    // Code
    if (condition) break;
}

// for infinite loop
for (;;) {
    // Code
    if (condition) break;
}

// do-while infinite loop
do {
    // Code
    if (condition) break;
} while (1);
```

### Loop Variations

```c
#include <stdio.h>

int main() {
    int i;
    
    // Standard for loop
    for (i = 0; i < 5; i++) {
        printf("%d ", i);
    }
    printf("\n");
    
    // for loop without initialization
    i = 0;
    for (; i < 5; i++) {
        printf("%d ", i);
    }
    printf("\n");
    
    // for loop without update
    for (i = 0; i < 5;) {
        printf("%d ", i);
        i++;
    }
    printf("\n");
    
    // for loop with comma operator
    for (int a = 0, b = 10; a < 5; a++, b--) {
        printf("a=%d, b=%d\n", a, b);
    }
    
    return 0;
}
```

## 📝 Practice Problems

### Problem 1: Prime Number Checker

```c
#include <stdio.h>
#include <math.h>

int main() {
    int num, isPrime = 1;
    
    printf("Enter a number: ");
    scanf("%d", &num);
    
    if (num <= 1) {
        isPrime = 0;
    } else {
        for (int i = 2; i <= sqrt(num); i++) {
            if (num % i == 0) {
                isPrime = 0;
                break;
            }
        }
    }
    
    if (isPrime) {
        printf("%d is a prime number\n", num);
    } else {
        printf("%d is not a prime number\n", num);
    }
    
    return 0;
}
```

### Problem 2: Fibonacci Series

```c
#include <stdio.h>

int main() {
    int n, first = 0, second = 1, next;
    
    printf("Enter number of terms: ");
    scanf("%d", &n);
    
    printf("Fibonacci Series: ");
    
    for (int i = 0; i < n; i++) {
        if (i == 0) {
            printf("%d ", first);
        } else if (i == 1) {
            printf("%d ", second);
        } else {
            next = first + second;
            printf("%d ", next);
            first = second;
            second = next;
        }
    }
    printf("\n");
    
    return 0;
}
```

### Problem 3: Armstrong Number

```c
#include <stdio.h>
#include <math.h>

int main() {
    int num, originalNum, remainder, digits = 0;
    double result = 0.0;
    
    printf("Enter a number: ");
    scanf("%d", &num);
    
    originalNum = num;
    
    // Count digits
    while (originalNum != 0) {
        originalNum /= 10;
        digits++;
    }
    
    originalNum = num;
    
    // Calculate sum of power of digits
    while (originalNum != 0) {
        remainder = originalNum % 10;
        result += pow(remainder, digits);
        originalNum /= 10;
    }
    
    if ((int)result == num) {
        printf("%d is an Armstrong number\n", num);
    } else {
        printf("%d is not an Armstrong number\n", num);
    }
    
    return 0;
}
```

---

# Unit 5: Arrays

## 📦 Introduction to Arrays

An **array** is a collection of elements of the same data type stored in contiguous memory locations. Arrays provide a way to store multiple values under a single variable name.

### Why Use Arrays?

**Without Arrays:**
```c
int student1 = 85;
int student2 = 90;
int student3 = 78;
int student4 = 92;
int student5 = 88;
// Imagine managing 100 students!
```

**With Arrays:**
```c
int students[5] = {85, 90, 78, 92, 88};
// Can easily manage any number of students
```

### Array Characteristics

| Property | Description |
|----------|-------------|
| **Fixed Size** | Size must be specified at declaration |
| **Same Data Type** | All elements must be of same type |
| **Contiguous Memory** | Elements stored in adjacent memory locations |
| **Zero-Indexed** | First element is at index 0 |
| **Random Access** | Any element can be accessed directly |

## 📊 One-Dimensional Arrays

### Declaration Syntax

```c
datatype array_name[size];

// Examples
int numbers[10];      // Array of 10 integers
float prices[50];     // Array of 50 floats
char name[30];        // Array of 30 characters (string)
```

### Initialization Methods

```c
// Method 1: Initialize at declaration
int marks[5] = {85, 90, 78, 92, 88};

// Method 2: Partial initialization (rest become 0)
int scores[10] = {1, 2, 3};  // Rest 7 elements are 0

// Method 3: Size determined by initializer
int nums[] = {10, 20, 30, 40};  // Size = 4

// Method 4: Initialize all to zero
int zeros[100] = {0};

// Method 5: Initialize after declaration
int values[5];
values[0] = 10;
values[1] = 20;
// ... and so on
```

### Memory Representation

```
Array: int arr[5] = {10, 20, 30, 40, 50};

Memory:
Address:  1000   1004   1008   1012   1016
        ┌──────┬──────┬──────┬──────┬──────┐
Value:  │  10  │  20  │  30  │  40  │  50  │
        └──────┴──────┴──────┴──────┴──────┘
Index:     0      1      2      3      4
```

### Accessing Array Elements

```c
#include <stdio.h>

int main() {
    int arr[5] = {10, 20, 30, 40, 50};
    
    // Access using index
    printf("First element: %d\n", arr[0]);
    printf("Last element: %d\n", arr[4]);
    
    // Modify elements
    arr[2] = 35;
    printf("Modified third element: %d\n", arr[2]);
    
    // Using loops to access
    printf("\nAll elements:\n");
    for (int i = 0; i < 5; i++) {
        printf("arr[%d] = %d\n", i, arr[i]);
    }
    
    return 0;
}
```

### Input and Output Operations

```c
#include <stdio.h>