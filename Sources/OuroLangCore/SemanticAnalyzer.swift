import Foundation

/// SemanticAnalyzer performs symbol resolution and basic type checking on the AST
public class SemanticAnalyzer {
    private let symbols = SymbolTable()

    public init() {}

    /// Analyze a list of top-level declarations
    public func analyze(_ decls: [Decl]) throws {
        // First pass: define all types and global functions/variables
        for decl in decls {
            switch decl {
            case let classDecl as ClassDecl:
                let typeDef = TypeDefinition(
                    name: classDecl.name.text,
                    isInterface: false,
                    isAbstract: false,
                    isSealed: false,
                    isPrimitive: false,
                    line: classDecl.line,
                    column: classDecl.column
                )
                try symbols.define(typeDef)
            case let structDecl as StructDecl:
                let typeDef = TypeDefinition(
                    name: structDecl.name.text,
                    isInterface: false,
                    isAbstract: false,
                    isSealed: false,
                    isPrimitive: false,
                    line: structDecl.line,
                    column: structDecl.column
                )
                try symbols.define(typeDef)
            case let enumDecl as EnumDecl:
                let typeDef = TypeDefinition(
                    name: enumDecl.name.text,
                    isInterface: false,
                    isAbstract: false,
                    isSealed: false,
                    isPrimitive: false,
                    line: enumDecl.line,
                    column: enumDecl.column
                )
                try symbols.define(typeDef)
            case let interfaceDecl as InterfaceDecl:
                let typeDef = TypeDefinition(
                    name: interfaceDecl.name.text,
                    isInterface: true,
                    isAbstract: true,
                    isSealed: false,
                    isPrimitive: false,
                    line: interfaceDecl.line,
                    column: interfaceDecl.column
                )
                try symbols.define(typeDef)
            case let funcDecl as FunctionDecl:
                // define global function as method symbol in global scope
                let returnType = funcDecl.returnType.flatMap { symbols.resolveType($0.name.text) }
                let params: [ParameterSymbol] = funcDecl.params.map {
                    let t = symbols.resolveType($0.type.name.text)!
                    return ParameterSymbol(name: $0.name.text, type: t, hasDefaultValue: $0.defaultValue != nil, line: funcDecl.line, column: funcDecl.column)
                }
                let methodSym = MethodSymbol(
                    name: funcDecl.name.text,
                    returnType: returnType,
                    parameters: params,
                    isStatic: false,
                    isAbstract: false,
                    isOverride: false,
                    isConstructor: false,
                    isAsync: false,
                    line: funcDecl.line,
                    column: funcDecl.column
                )
                try symbols.define(methodSym)
            case let varDecl as VarDecl:
                let varType = varDecl.typeAnnotation.flatMap { symbols.resolveType($0.name.text) } ?? symbols.getPrimitiveType("Void")!
                let varSym = VariableSymbol(
                    name: varDecl.name.text,
                    type: varType,
                    isMutable: true,
                    line: varDecl.line,
                    column: varDecl.column
                )
                try symbols.define(varSym)
            default:
                break
            }
        }
        // Second pass: analyze declarations and statements with scope management
        for decl in decls {
            try analyzeDeclaration(decl)
        }
    }

    // MARK: - Semantic Analysis Helpers
    private func analyzeDeclaration(_ decl: Decl) throws {
        switch decl {
        case let varDecl as VarDecl:
            try analyzeVarDecl(varDecl)
        case let funcDecl as FunctionDecl:
            try analyzeFunctionDecl(funcDecl)
        case let classDecl as ClassDecl:
            try analyzeClassDecl(classDecl)
        case let structDecl as StructDecl:
            try analyzeStructDecl(structDecl)
        case let enumDecl as EnumDecl:
            try analyzeEnumDecl(enumDecl)
        case let interfaceDecl as InterfaceDecl:
            try analyzeInterfaceDecl(interfaceDecl)
        default:
            break
        }
    }

    private func analyzeVarDecl(_ decl: VarDecl) throws {
        if let initExpr = decl.initializer {
            try analyzeExpression(initExpr)
        }
    }

    private func analyzeFunctionDecl(_ decl: FunctionDecl) throws {
        symbols.enterScope()
        // Define parameters
        for param in decl.params {
            let paramType = symbols.resolveType(param.type.name.text) ?? symbols.getPrimitiveType("Void")!
            let paramSym = ParameterSymbol(name: param.name.text, type: paramType, hasDefaultValue: param.defaultValue != nil, line: decl.line, column: decl.column)
            try symbols.define(paramSym)
        }
        // Analyze body
        for stmt in decl.body.statements {
            try analyzeStatement(stmt)
        }
        symbols.exitScope()
    }

    private func analyzeClassDecl(_ decl: ClassDecl) throws {
        // Resolve type definition
        guard let typeDef = symbols.resolveType(decl.name.text) else { return }
        // Set supertype
        if let superNode = decl.superclass, let superType = symbols.resolveType(superNode.name.text) {
            typeDef.superType = superType
        }
        // Set interfaces
        for ifaceNode in decl.interfaces {
            if let ifaceType = symbols.resolveType(ifaceNode.name.text) {
                typeDef.interfaces.append(ifaceType)
            }
        }
        // Enter class scope
        symbols.enterScope(enclosingType: typeDef)
        // Define properties
        for prop in decl.properties {
            let propType = prop.typeAnnotation.flatMap { symbols.resolveType($0.name.text) } ?? symbols.getPrimitiveType("Void")!
            let varSym = VariableSymbol(name: prop.name.text, type: propType, isMutable: true, line: prop.line, column: prop.column)
            typeDef.properties.append(varSym)
            try symbols.define(varSym)
            if let initExpr = prop.initializer {
                try analyzeExpression(initExpr)
            }
        }
        // Define methods
        for method in decl.methods {
            let returnType = method.returnType.flatMap { symbols.resolveType($0.name.text) }
            let paramsSymbols: [ParameterSymbol] = method.params.map {
                let t = symbols.resolveType($0.type.name.text) ?? symbols.getPrimitiveType("Void")!
                return ParameterSymbol(name: $0.name.text, type: t, hasDefaultValue: $0.defaultValue != nil, line: method.line, column: method.column)
            }
            let methodSym = MethodSymbol(name: method.name.text, returnType: returnType, parameters: paramsSymbols, isStatic: false, isAbstract: false, isOverride: false, isConstructor: false, isAsync: false, line: method.line, column: method.column)
            typeDef.methods.append(methodSym)
            try symbols.define(methodSym)
        }
        // Analyze methods bodies
        for method in decl.methods {
            try analyzeFunctionDecl(method)
        }
        symbols.exitScope()
    }

    private func analyzeStructDecl(_ decl: StructDecl) throws {
        guard let typeDef = symbols.resolveType(decl.name.text) else { return }
        symbols.enterScope(enclosingType: typeDef)
        // Define properties
        for prop in decl.properties {
            let propType = prop.typeAnnotation.flatMap { symbols.resolveType($0.name.text) } ?? symbols.getPrimitiveType("Void")!
            let varSym = VariableSymbol(name: prop.name.text, type: propType, isMutable: true, line: prop.line, column: prop.column)
            typeDef.properties.append(varSym)
            try symbols.define(varSym)
            if let initExpr = prop.initializer {
                try analyzeExpression(initExpr)
            }
        }
        // Define and analyze methods
        for method in decl.methods {
            let returnType = method.returnType.flatMap { symbols.resolveType($0.name.text) }
            let paramsSymbols: [ParameterSymbol] = method.params.map {
                let t = symbols.resolveType($0.type.name.text) ?? symbols.getPrimitiveType("Void")!
                return ParameterSymbol(name: $0.name.text, type: t, hasDefaultValue: $0.defaultValue != nil, line: method.line, column: method.column)
            }
            let methodSym = MethodSymbol(name: method.name.text, returnType: returnType, parameters: paramsSymbols, isStatic: false, isAbstract: false, isOverride: false, isConstructor: false, isAsync: false, line: method.line, column: method.column)
            typeDef.methods.append(methodSym)
            try symbols.define(methodSym)
            try analyzeFunctionDecl(method)
        }
        symbols.exitScope()
    }

    private func analyzeEnumDecl(_ decl: EnumDecl) throws {
        guard let typeDef = symbols.resolveType(decl.name.text) else { return }
        symbols.enterScope(enclosingType: typeDef)
        // Define cases
        for enumCase in decl.cases {
            let varSym = VariableSymbol(name: enumCase.name.text, type: typeDef, isMutable: false, line: enumCase.name.line, column: enumCase.name.column)
            typeDef.properties.append(varSym)
            try symbols.define(varSym)
        }
        // Define and analyze methods
        for method in decl.methods {
            let returnType = method.returnType.flatMap { symbols.resolveType($0.name.text) }
            let paramsSymbols: [ParameterSymbol] = method.params.map {
                let t = symbols.resolveType($0.type.name.text) ?? symbols.getPrimitiveType("Void")!
                return ParameterSymbol(name: $0.name.text, type: t, hasDefaultValue: $0.defaultValue != nil, line: method.line, column: method.column)
            }
            let methodSym = MethodSymbol(name: method.name.text, returnType: returnType, parameters: paramsSymbols, isStatic: false, isAbstract: false, isOverride: false, isConstructor: false, isAsync: false, line: method.line, column: method.column)
            typeDef.methods.append(methodSym)
            try symbols.define(methodSym)
            try analyzeFunctionDecl(method)
        }
        symbols.exitScope()
    }

    private func analyzeInterfaceDecl(_ decl: InterfaceDecl) throws {
        guard let typeDef = symbols.resolveType(decl.name.text) else { return }
        symbols.enterScope(enclosingType: typeDef)
        // Define methods
        for method in decl.methods {
            let returnType = method.returnType.flatMap { symbols.resolveType($0.name.text) }
            let paramsSymbols: [ParameterSymbol] = method.params.map {
                let t = symbols.resolveType($0.type.name.text) ?? symbols.getPrimitiveType("Void")!
                return ParameterSymbol(name: $0.name.text, type: t, hasDefaultValue: $0.defaultValue != nil, line: method.line, column: method.column)
            }
            let methodSym = MethodSymbol(name: method.name.text, returnType: returnType, parameters: paramsSymbols, isStatic: false, isAbstract: true, isOverride: false, isConstructor: false, isAsync: false, line: method.line, column: method.column)
            typeDef.methods.append(methodSym)
            try symbols.define(methodSym)
        }
        symbols.exitScope()
    }

    private func analyzeStatement(_ stmt: Stmt) throws {
        switch stmt {
        case let exprStmt as ExpressionStmt:
            try analyzeExpression(exprStmt.expression)
        case let block as BlockStmt:
            symbols.enterScope()
            for s in block.statements { try analyzeStatement(s) }
            symbols.exitScope()
        case let ifStmt as IfStmt:
            try analyzeExpression(ifStmt.condition)
            try analyzeStatement(ifStmt.thenBranch)
            if let elseBranch = ifStmt.elseBranch { try analyzeStatement(elseBranch) }
        case let whileStmt as WhileStmt:
            try analyzeExpression(whileStmt.condition)
            symbols.enterScope()
            try analyzeStatement(whileStmt.body)
            symbols.exitScope()
        case let forStmt as ForStmt:
            symbols.enterScope()
            if let initStmt = forStmt.initializer { try analyzeStatement(initStmt) }
            if let condition = forStmt.condition { try analyzeExpression(condition) }
            if let increment = forStmt.increment { try analyzeExpression(increment) }
            try analyzeStatement(forStmt.body)
            symbols.exitScope()
        case let varDecl as VarDecl:
            let varType = varDecl.typeAnnotation.flatMap { symbols.resolveType($0.name.text) } ?? symbols.getPrimitiveType("Void")!
            let varSym = VariableSymbol(name: varDecl.name.text, type: varType, isMutable: true, line: varDecl.line, column: varDecl.column)
            try symbols.define(varSym)
            if let initExpr = varDecl.initializer { try analyzeExpression(initExpr) }
        case let returnStmt as ReturnStmt:
            if let value = returnStmt.value { try analyzeExpression(value) }
        default:
            break
        }
    }

    private func analyzeExpression(_ expr: Expr) throws {
        switch expr {
        case let binary as BinaryExpr:
            try analyzeExpression(binary.left)
            try analyzeExpression(binary.right)
        case let grouping as GroupingExpr:
            try analyzeExpression(grouping.expression)
        case _ as LiteralExpr:
            break
        case let unary as UnaryExpr:
            try analyzeExpression(unary.right)
        case let varExpr as VariableExpr:
            if symbols.resolveVariable(varExpr.name.text) == nil {
                throw SymbolError.symbolNotFound(varExpr.name.text, line: varExpr.line, column: varExpr.column)
            }
        case let call as CallExpr:
            try analyzeExpression(call.callee)
            for arg in call.arguments { try analyzeExpression(arg) }
        case let getExpr as GetExpr:
            try analyzeExpression(getExpr.object)
        case let setExpr as SetExpr:
            try analyzeExpression(setExpr.object)
            try analyzeExpression(setExpr.value)
        case _ as ThisExpr, _ as SuperExpr:
            break
        case let arrayExpr as ArrayExpr:
            for el in arrayExpr.elements { try analyzeExpression(el) }
        case let indexExpr as IndexExpr:
            try analyzeExpression(indexExpr.array)
            try analyzeExpression(indexExpr.index)
        default:
            break
        }
    }
} 