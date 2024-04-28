pub type CallArguments {
  CallArguments(List(Expression))
}

pub type Call {
  FunctionCall(function: Expression, arguments: CallArguments)

  MethodCall(
    subject: Expression,
    method_identifier: String,
    arguments: CallArguments,
  )
}

pub type Expression {
  ExpressionSymbol(identifier: String)
  ExpressionRaiseEffect(Expression)
  ExpressionCall(Call)
  ExpressionUnaryOperation(operator: String, argument: Expression)
  ExpressionBinaryOperation(operator: String, lhs: Expression, rhs: Expression)
  ExpressionBlock(statements: List(Statement))
}

pub type Let {
  LetUntyped(identifier: String, value: Expression)
  LetTyped(identifier: String, typ: Expression, value: Expression)
}

pub type Statement {
  StatementLet(Let)
  StatementExpression(Expression)
}
