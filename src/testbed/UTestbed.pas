{===============================================================================
  Myra™ - Pascal. Refined.

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://myralang.org

  See LICENSE for license information
===============================================================================}

unit UTestbed;

interface

procedure RunTestbed();

implementation

uses
  System.SysUtils,
  System.IOUtils,
  Myra.Utils,
  UTester;

type
  TTestDef = record
    Num: Integer;
    TestName: string;
    ExpectedExitCode: Integer;
  end;

const
  CTests: array[0..115] of TTestDef = (
    //==========================================================================
    // ARRAY (001-049)
    //==========================================================================
    (Num: 001; TestName: 'Test_Array_Assign'; ExpectedExitCode: 0),
    (Num: 002; TestName: 'Test_Array_Bounds'; ExpectedExitCode: 0),
    (Num: 003; TestName: 'Test_Array_Dynamic'; ExpectedExitCode: 0),
    (Num: 004; TestName: 'Test_Array_Index'; ExpectedExitCode: 0),
    (Num: 005; TestName: 'Test_Array_Loop'; ExpectedExitCode: 0),
    (Num: 006; TestName: 'Test_Array_MultiDim'; ExpectedExitCode: 0),
    (Num: 007; TestName: 'Test_Array_OpenParam'; ExpectedExitCode: 0),

    //==========================================================================
    // CONST (050-099)
    //==========================================================================
    (Num: 050; TestName: 'Test_Const_Boolean'; ExpectedExitCode: 0),
    (Num: 051; TestName: 'Test_Const_Float'; ExpectedExitCode: 0),
    (Num: 052; TestName: 'Test_Const_Integer'; ExpectedExitCode: 0),
    (Num: 053; TestName: 'Test_Const_Public'; ExpectedExitCode: 0),
    (Num: 054; TestName: 'Test_Const_Public_Use'; ExpectedExitCode: 0),
    (Num: 055; TestName: 'Test_Const_String'; ExpectedExitCode: 0),
    (Num: 056; TestName: 'Test_Const_Typed'; ExpectedExitCode: 0),

    //==========================================================================
    // EXPR (100-149)
    //==========================================================================
    (Num: 100; TestName: 'Test_Expr_Arithmetic'; ExpectedExitCode: 0),
    (Num: 101; TestName: 'Test_Expr_Comparison'; ExpectedExitCode: 0),
    (Num: 102; TestName: 'Test_Expr_Logical'; ExpectedExitCode: 0),
    (Num: 103; TestName: 'Test_Expr_TypeOps'; ExpectedExitCode: 0),

    //==========================================================================
    // INTEROP (150-199)
    //==========================================================================
    (Num: 150; TestName: 'Test_Interop_ConditionalCompile'; ExpectedExitCode: 0),
    (Num: 151; TestName: 'Test_Interop_CppBlock'; ExpectedExitCode: 0),
    (Num: 152; TestName: 'Test_Interop_CppPassthrough'; ExpectedExitCode: 0),
    (Num: 153; TestName: 'Test_Interop_DllAbiExport'; ExpectedExitCode: 0),
    (Num: 154; TestName: 'Test_Interop_DllImport'; ExpectedExitCode: 0),
    (Num: 155; TestName: 'Test_Interop_Emit'; ExpectedExitCode: 0),
    (Num: 156; TestName: 'Test_Interop_IncludeHeader'; ExpectedExitCode: 0),
    (Num: 157; TestName: 'Test_Interop_WideString'; ExpectedExitCode: 0),
    (Num: 158; TestName: 'Test_Interop_CppOperators'; ExpectedExitCode: 0),

    //==========================================================================
    // MODULE (200-249)
    //==========================================================================
    (Num: 200; TestName: 'Test_Module_Assertions'; ExpectedExitCode: 0),
    (Num: 201; TestName: 'Test_Module_CommandLine'; ExpectedExitCode: 0),
    (Num: 202; TestName: 'Test_Module_Console'; ExpectedExitCode: 0),
    (Num: 203; TestName: 'Test_Module_ConsoleUTF8'; ExpectedExitCode: 0),
    (Num: 204; TestName: 'Test_Module_Directives'; ExpectedExitCode: 0),
    (Num: 205; TestName: 'Test_Module_DllNoBody'; ExpectedExitCode: 0),
    (Num: 206; TestName: 'Test_Module_ExeWithBody'; ExpectedExitCode: 0),
    (Num: 207; TestName: 'Test_Module_Hello'; ExpectedExitCode: 0),
    (Num: 208; TestName: 'Test_Module_HelloWorld'; ExpectedExitCode: 0),
    (Num: 209; TestName: 'Test_Module_ImportMultiple'; ExpectedExitCode: 0),
    (Num: 210; TestName: 'Test_Module_ImportSingle'; ExpectedExitCode: 0),
    (Num: 211; TestName: 'Test_Module_Library'; ExpectedExitCode: 0),
    (Num: 212; TestName: 'Test_Module_Minimal'; ExpectedExitCode: 0),
    (Num: 213; TestName: 'Test_Module_PublicRoutine'; ExpectedExitCode: 0),
    (Num: 214; TestName: 'Test_Module_System'; ExpectedExitCode: 0),
    (Num: 215; TestName: 'Test_Module_ValidLib'; ExpectedExitCode: 0),

    //==========================================================================
    // POINTER (250-299)
    //==========================================================================
    (Num: 250; TestName: 'Test_Pointer_Deref'; ExpectedExitCode: 0),
    (Num: 251; TestName: 'Test_Pointer_NewDispose'; ExpectedExitCode: 0),
    (Num: 252; TestName: 'Test_Pointer_Nil'; ExpectedExitCode: 0),

    //==========================================================================
    // POLY (300-349)
    //==========================================================================
    (Num: 300; TestName: 'Test_Poly_AsOperator'; ExpectedExitCode: 0),
    (Num: 301; TestName: 'Test_Poly_IsOperator'; ExpectedExitCode: 0),
    (Num: 302; TestName: 'Test_Poly_MethodInherited'; ExpectedExitCode: 0),
    (Num: 303; TestName: 'Test_Poly_MethodsCppMixed'; ExpectedExitCode: 0),
    (Num: 304; TestName: 'Test_Poly_ShapeLibrary'; ExpectedExitCode: 0),
    (Num: 305; TestName: 'Test_Poly_TypeExtend'; ExpectedExitCode: 0),
    (Num: 306; TestName: 'Test_Poly_VirtualDispatch'; ExpectedExitCode: 0),

    //==========================================================================
    // RECORD (350-399)
    //==========================================================================
    (Num: 350; TestName: 'Test_Record_FieldAccess'; ExpectedExitCode: 0),
    (Num: 351; TestName: 'Test_Record_Inheritance'; ExpectedExitCode: 0),

    //==========================================================================
    // ROUTINE (400-449)
    //==========================================================================
    (Num: 400; TestName: 'Test_Routine_ConstParams'; ExpectedExitCode: 0),
    (Num: 401; TestName: 'Test_Routine_External'; ExpectedExitCode: 0),
    (Num: 402; TestName: 'Test_Routine_Method'; ExpectedExitCode: 0),
    (Num: 403; TestName: 'Test_Routine_NoParams'; ExpectedExitCode: 0),
    (Num: 404; TestName: 'Test_Routine_Public'; ExpectedExitCode: 0),
    (Num: 405; TestName: 'Test_Routine_VarParams'; ExpectedExitCode: 0),

    //==========================================================================
    // SET (450-499)
    //==========================================================================
    (Num: 450; TestName: 'Test_Set_Comprehensive'; ExpectedExitCode: 0),
    (Num: 451; TestName: 'Test_Set_Literals'; ExpectedExitCode: 0),
    (Num: 452; TestName: 'Test_Set_Membership'; ExpectedExitCode: 0),
    (Num: 453; TestName: 'Test_Set_Operations'; ExpectedExitCode: 0),

    //==========================================================================
    // STMT (500-549)
    //==========================================================================
    (Num: 500; TestName: 'Test_Stmt_Case'; ExpectedExitCode: 0),
    (Num: 501; TestName: 'Test_Stmt_For'; ExpectedExitCode: 0),
    (Num: 502; TestName: 'Test_Stmt_If'; ExpectedExitCode: 0),
    (Num: 503; TestName: 'Test_Stmt_Repeat'; ExpectedExitCode: 0),
    (Num: 504; TestName: 'Test_Stmt_Return'; ExpectedExitCode: 0),
    (Num: 505; TestName: 'Test_Stmt_Try'; ExpectedExitCode: 0),
    (Num: 506; TestName: 'Test_Stmt_TryComprehensive'; ExpectedExitCode: 0),
    (Num: 507; TestName: 'Test_Stmt_While'; ExpectedExitCode: 0),

    //==========================================================================
    // TYPE (550-599)
    //==========================================================================
    (Num: 550; TestName: 'Test_Type_ArrayDynamic'; ExpectedExitCode: 0),
    (Num: 551; TestName: 'Test_Type_ArrayStatic'; ExpectedExitCode: 0),
    (Num: 552; TestName: 'Test_Type_Pointer'; ExpectedExitCode: 0),
    (Num: 553; TestName: 'Test_Type_Public'; ExpectedExitCode: 0),
    (Num: 554; TestName: 'Test_Type_RecordExtension'; ExpectedExitCode: 0),
    (Num: 555; TestName: 'Test_Type_RecordSimple'; ExpectedExitCode: 0),
    (Num: 556; TestName: 'Test_Type_Routine'; ExpectedExitCode: 0),
    (Num: 557; TestName: 'Test_Type_Set'; ExpectedExitCode: 0),
    (Num: 558; TestName: 'Test_Type_NumericPromotion'; ExpectedExitCode: 0),

    //==========================================================================
    // VAR (600-649)
    //==========================================================================
    (Num: 600; TestName: 'Test_Var_BasicTypes'; ExpectedExitCode: 0),
    (Num: 601; TestName: 'Test_Var_Init'; ExpectedExitCode: 0),
    (Num: 602; TestName: 'Test_Var_Init_UnitTest'; ExpectedExitCode: 0),
    (Num: 603; TestName: 'Test_Var_Local'; ExpectedExitCode: 0),
    (Num: 604; TestName: 'Test_Var_ModuleLevel'; ExpectedExitCode: 0),
    (Num: 605; TestName: 'Test_Var_Public'; ExpectedExitCode: 0),

    //==========================================================================
    // EDGE (650-699)
    //==========================================================================
    (Num: 650; TestName: 'Test_Edge_CaseMany'; ExpectedExitCode: 0),
    (Num: 651; TestName: 'Test_Edge_DeepNesting'; ExpectedExitCode: 0),
    (Num: 652; TestName: 'Test_Edge_EmptyBlock'; ExpectedExitCode: 0),
    (Num: 653; TestName: 'Test_Edge_LongExpression'; ExpectedExitCode: 0),
    (Num: 654; TestName: 'Test_Edge_ManyLocals'; ExpectedExitCode: 0),
    (Num: 655; TestName: 'Test_Edge_ManyParams'; ExpectedExitCode: 0),
    (Num: 656; TestName: 'Test_Edge_Recursion'; ExpectedExitCode: 0),
    (Num: 657; TestName: 'Test_Edge_SetMaxBits'; ExpectedExitCode: 0),
    (Num: 658; TestName: 'Test_Edge_StringEscape'; ExpectedExitCode: 0),

    //==========================================================================
    // MULTI (700-749)
    //==========================================================================
    (Num: 700; TestName: 'Test_Multi_ChainedImport'; ExpectedExitCode: 0),
    (Num: 701; TestName: 'Test_Multi_ConstLib'; ExpectedExitCode: 0),
    (Num: 702; TestName: 'Test_Multi_DllAbiExport'; ExpectedExitCode: 0),
    (Num: 703; TestName: 'Test_Multi_ImportConst'; ExpectedExitCode: 0),
    (Num: 704; TestName: 'Test_Multi_ImportRoutine'; ExpectedExitCode: 0),
    (Num: 705; TestName: 'Test_Multi_ImportType'; ExpectedExitCode: 0),
    (Num: 706; TestName: 'Test_Multi_QualifiedAccess'; ExpectedExitCode: 0),
    (Num: 707; TestName: 'Test_Multi_RoutineLib'; ExpectedExitCode: 0),
    (Num: 708; TestName: 'Test_Multi_TypeLib'; ExpectedExitCode: 0),
    (Num: 709; TestName: 'Test_Multi_UseChained'; ExpectedExitCode: 0),

    //==========================================================================
    // PATTERN (750-799)
    //==========================================================================
    (Num: 750; TestName: 'Test_Pattern_Integration'; ExpectedExitCode: 0),
    (Num: 751; TestName: 'Test_Pattern_SetsCppMixed'; ExpectedExitCode: 0),

    //==========================================================================
    // REAL (800-849)
    //==========================================================================
    (Num: 800; TestName: 'Test_Real_RaylibStatic'; ExpectedExitCode: 0),
    (Num: 801; TestName: 'Test_Real_Exceptions'; ExpectedExitCode: 0),
    (Num: 802; TestName: 'Test_Real_OOPMixedMode'; ExpectedExitCode: 0),
    (Num: 803; TestName: 'Test_Real_UnitTestDemo'; ExpectedExitCode: 0),
    (Num: 804; TestName: 'Test_Real_UnitTesting'; ExpectedExitCode: 0),
    (Num: 805; TestName: 'Test_Real_RTLModules'; ExpectedExitCode: 0),

    //==========================================================================
    // DIRECTIVE (850-899)
    //==========================================================================
    (Num: 850; TestName: 'Test_Directive_Breakpoint'; ExpectedExitCode: 0)
  );

type
  TFailedTest = record
    Num: Integer;
    TestName: string;
  end;



function FindTestByNum(const ANum: Integer; out ATest: TTestDef): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := Low(CTests) to High(CTests) do
  begin
    if CTests[I].Num = ANum then
    begin
      ATest := CTests[I];
      Result := True;
      Exit;
    end;
  end;
end;

procedure RunAllTests();
var
  I: Integer;
  LPassed: Integer;
  LFailed: Integer;
  LTotal: Integer;
  LSuccess: Boolean;
  LFailedTests: array of TFailedTest;
  LTest: TTestDef;
  LPadded: string;
begin
  LPassed := 0;
  LFailed := 0;
  LTotal := Length(CTests);
  SetLength(LFailedTests, 0);

  TUtils.PrintLn('');
  TUtils.PrintLn(COLOR_CYAN + '===============================================================================');
  TUtils.PrintLn('  MYRA AUTOMATED TEST SUITE');
  TUtils.PrintLn('===============================================================================' + COLOR_RESET);
  TUtils.PrintLn('');
  TUtils.PrintLn(Format('Running %d tests...', [LTotal]));
  TUtils.PrintLn('');

  for I := Low(CTests) to High(CTests) do
  begin
    LTest := CTests[I];

    // Format: [001] Test_Array_Assign.................. PASS
    LPadded := Format('[%.3d] %s ', [LTest.Num, LTest.TestName]);
    while Length(LPadded) < 55 do
      LPadded := LPadded + '.';

    TUtils.PrintLn(LPadded + ' ');

    LSuccess := TestFile(
      LTest.TestName,
      True,   // ARun
      False,  // AClean
      LTest.ExpectedExitCode,
      True    // AQuiet
    );

    if LSuccess then
    begin
      Inc(LPassed);
      TUtils.PrintLn(COLOR_GREEN + 'PASS' + COLOR_RESET);
    end
    else
    begin
      Inc(LFailed);
      TUtils.PrintLn(COLOR_RED + 'FAIL' + COLOR_RESET);

      // Track failed test
      SetLength(LFailedTests, Length(LFailedTests) + 1);
      LFailedTests[High(LFailedTests)].Num := LTest.Num;
      LFailedTests[High(LFailedTests)].TestName := LTest.TestName;
    end;
  end;

  // Summary
  TUtils.PrintLn('');
  TUtils.PrintLn('===============================================================================');

  if LFailed = 0 then
    TUtils.PrintLn(COLOR_GREEN + Format('  RESULTS: %d/%d passed, %d failed', [LPassed, LTotal, LFailed]) + COLOR_RESET)
  else
    TUtils.PrintLn(COLOR_YELLOW + Format('  RESULTS: %d/%d passed, %d failed', [LPassed, LTotal, LFailed]) + COLOR_RESET);

  TUtils.PrintLn('===============================================================================');

  // List failed tests
  if LFailed > 0 then
  begin
    TUtils.PrintLn('');
    TUtils.PrintLn(COLOR_RED + '  FAILED TESTS:' + COLOR_RESET);
    for I := 0 to High(LFailedTests) do
    begin
      TUtils.PrintLn(Format('    [%.3d] %s', [LFailedTests[I].Num, LFailedTests[I].TestName]));
    end;
    TUtils.PrintLn('===============================================================================');
  end;

  TUtils.PrintLn('');
end;

procedure RunTestbed();
var
  LNum: Integer;
  LTest: TTestDef;
begin
  try
    LNum := 0;
    //LNum := 850;
    //LNum := 304;

    // Automated test mode
    if LNum = 0 then
    begin
      RunAllTests();
    end
    // Special tests (not in CTests array)
    else if LNum = 1000 then
    begin
      TestFile('Test01', True, False, 0, False);
    end
    // Standard test from registry
    else if FindTestByNum(LNum, LTest) then
    begin
      TestFile(LTest.TestName, True, False, LTest.ExpectedExitCode, False);
    end
    else
    begin
      TUtils.PrintLn(COLOR_RED + Format('  [ERR] Unknown test number: %d', [LNum]) + COLOR_RESET);
    end;

  except
    on E: Exception do
    begin
      TUtils.PrintLn('');
      TUtils.PrintLn(COLOR_RED + '  [EXCEPTION] ' + COLOR_RESET + E.ClassName);
      TUtils.PrintLn('  ' + E.Message);
    end;
  end;

  TUtils.Pause();
end;

end.
