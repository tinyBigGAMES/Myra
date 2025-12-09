{===============================================================================
  Myra™ - Pascal. Refined.

  Copyright © 2025-present tinyBigGAMES™ LLC
  All Rights Reserved.

  https://myralang.org

  See LICENSE for license information
===============================================================================}

unit Myra.Debug.REPL;

{$I Myra.Defines.inc}

interface

uses
  System.SysUtils,
  System.StrUtils,
  System.IOUtils,
  System.Generics.Collections,
  Myra.Utils,
  Myra.Debug;

type
  { TDebugREPL }
  TDebugREPL = class(TBaseObject)
  private
    FDebugger: TDebug;
    FPrompt: string;
    FRunning: Boolean;
    FExePath: string;
    FPasFile: string;

    procedure ProcessCommand(const ACommand: string);
    procedure ShowHelp();
    procedure HandleSetBreakpoint(const ACommand: string);
    procedure HandleListBreakpoints();
    procedure HandleDeleteBreakpoint(const ACommand: string);
    procedure HandleClearBreakpoints();
    procedure HandleThreads();
    procedure HandleBacktrace();
    procedure HandleLocals();
    procedure HandlePrint(const ACommand: string);
    procedure HandleContinue();
    procedure HandleNext();
    procedure HandleStepInto();
    procedure HandleStepOut();
    procedure HandleRestart();
    procedure HandleFile(const ACommand: string);
    procedure HandleVerbose(const ACommand: string);

  public
    constructor Create(); override;
    destructor Destroy; override;

    procedure Run(const AExePath: string; const APasFile: string);
    procedure Stop();

    property Debugger: TDebug read FDebugger write FDebugger;
    property Prompt: string read FPrompt write FPrompt;
  end;

implementation

{ TDebugREPL }

constructor TDebugREPL.Create();
begin
  inherited;

  FDebugger := nil;
  FPrompt := '(lldb-dap) ';
  FRunning := False;
  FExePath := '';
  FPasFile := '';
end;

destructor TDebugREPL.Destroy();
begin
  Stop();
  inherited;
end;

procedure TDebugREPL.ShowHelp();
begin
  TUtils.PrintLn('Commands:');
  TUtils.PrintLn('  h, help         - Show this help');
  TUtils.PrintLn('  b <file>:<line> - Set breakpoint');
  TUtils.PrintLn('  bl              - List breakpoints');
  TUtils.PrintLn('  bd <id>         - Delete breakpoint by ID');
  TUtils.PrintLn('  bc              - Clear all breakpoints');
  TUtils.PrintLn('  threads         - Show threads');
  TUtils.PrintLn('  bt              - Show call stack (backtrace)');
  TUtils.PrintLn('  locals          - Show local variables');
  TUtils.PrintLn('  p <expr>        - Print/evaluate expression');
  TUtils.PrintLn('  c               - Continue execution');
  TUtils.PrintLn('  n               - Next (step over)');
  TUtils.PrintLn('  s               - Step into');
  TUtils.PrintLn('  finish          - Step out');
  TUtils.PrintLn('  r               - Run/restart program');
  TUtils.PrintLn('  file <path>     - Load different executable');
  TUtils.PrintLn('  verbose on      - Enable DAP message logging');
  TUtils.PrintLn('  verbose off     - Disable DAP message logging');
  TUtils.PrintLn('  quit            - Exit REPL');
end;

procedure TDebugREPL.HandleSetBreakpoint(const ACommand: string);
var
  LI: Integer;
  LFile: string;
  LLine: Integer;
begin
  // Set breakpoint: b <file>:<line>
  LI := Pos(':', ACommand);
  if LI > 3 then
  begin
    LFile := Trim(Copy(ACommand, 3, LI - 3));  // file path
    LLine := StrToIntDef(Trim(Copy(ACommand, LI + 1, MaxInt)), -1);  // line number

    if (LFile <> '') and (LLine > 0) then
    begin
      if FDebugger.SetBreakpoint(LFile, LLine) then
        TUtils.PrintLn(COLOR_GREEN + Format('Breakpoint set at %s:%d', [LFile, LLine]) + COLOR_RESET)
      else
        TUtils.PrintLn(COLOR_RED + 'Failed to set breakpoint: ' + FDebugger.GetLastError() + COLOR_RESET);
    end
    else
      TUtils.PrintLn(COLOR_RED + 'Invalid format. Use: b <file>:<line>' + COLOR_RESET);
  end
  else
    TUtils.PrintLn(COLOR_RED + 'Invalid format. Use: b <file>:<line>' + COLOR_RESET);
end;

procedure TDebugREPL.HandleListBreakpoints();
var
  LAllBreakpoints: TArray<TBreakpoint>;
  LI: Integer;
begin
  LAllBreakpoints := FDebugger.GetAllBreakpoints();
  if Length(LAllBreakpoints) = 0 then
    TUtils.PrintLn('No breakpoints set')
  else
  begin
    TUtils.PrintLn(Format('Total breakpoints: %d', [Length(LAllBreakpoints)]));
    for LI := 0 to High(LAllBreakpoints) do
      TUtils.PrintLn(Format('  #%d: %s:%d %s',
        [LI + 1, LAllBreakpoints[LI].FileName, LAllBreakpoints[LI].LineNumber,
         IfThen(LAllBreakpoints[LI].Verified, '[verified]', '[unverified]')]));
  end;
end;

procedure TDebugREPL.HandleDeleteBreakpoint(const ACommand: string);
var
  LI: Integer;
  LAllBreakpoints: TArray<TBreakpoint>;
begin
  LI := StrToIntDef(Trim(Copy(ACommand, 4, MaxInt)), -1);
  LAllBreakpoints := FDebugger.GetAllBreakpoints();
  if (LI > 0) and (LI <= Length(LAllBreakpoints)) then
  begin
    if FDebugger.RemoveBreakpoint(LAllBreakpoints[LI - 1].FileName, LAllBreakpoints[LI - 1].LineNumber) then
      TUtils.PrintLn(COLOR_GREEN + Format('Breakpoint #%d deleted', [LI]) + COLOR_RESET)
    else
      TUtils.PrintLn(COLOR_RED + 'Failed to delete breakpoint: ' + FDebugger.GetLastError() + COLOR_RESET);
  end
  else
    TUtils.PrintLn(COLOR_RED + 'Invalid breakpoint ID' + COLOR_RESET);
end;

procedure TDebugREPL.HandleClearBreakpoints();
begin
  if FDebugger.ClearAllBreakpoints() then
    TUtils.PrintLn(COLOR_GREEN + 'All breakpoints cleared' + COLOR_RESET)
  else
    TUtils.PrintLn(COLOR_RED + 'Failed to clear breakpoints' + COLOR_RESET);
end;

procedure TDebugREPL.HandleThreads();
var
  LThreads: TArray<TThreadInfo>;
  LThread: TThreadInfo;
begin
  LThreads := FDebugger.GetThreads();
  TUtils.PrintLn(Format('Found %d thread(s):', [Length(LThreads)]));
  for LThread in LThreads do
    TUtils.PrintLn(Format('  Thread %d: %s', [LThread.ID, LThread.ThreadName]));
end;

procedure TDebugREPL.HandleBacktrace();
var
  LStack: TArray<TStackFrame>;
  LFrame: TStackFrame;
begin
  if FDebugger.State <> dsStopped then
  begin
    TUtils.PrintLn(COLOR_RED + 'Not stopped' + COLOR_RESET);
    Exit;
  end;

  LStack := FDebugger.GetCallStack(FDebugger.CurrentThreadID);
  TUtils.PrintLn(Format('Call stack (%d frames):', [Length(LStack)]));
  for LFrame in LStack do
    TUtils.PrintLn(Format('  #%d: %s at %s:%d', [LFrame.ID, LFrame.FunctionName, LFrame.FileName, LFrame.LineNumber]));
end;

procedure TDebugREPL.HandleLocals();
var
  LStack: TArray<TStackFrame>;
  LVariables: TArray<TVariable>;
  LVar: TVariable;
begin
  if FDebugger.State <> dsStopped then
  begin
    TUtils.PrintLn(COLOR_RED + 'Not stopped' + COLOR_RESET);
    Exit;
  end;

  LStack := FDebugger.GetCallStack(FDebugger.CurrentThreadID);
  if Length(LStack) = 0 then
  begin
    TUtils.PrintLn(COLOR_RED + 'No stack frames available' + COLOR_RESET);
    Exit;
  end;

  LVariables := FDebugger.GetLocalVariables(LStack[0].ID);
  if Length(LVariables) = 0 then
    TUtils.PrintLn('No local variables')
  else
  begin
    TUtils.PrintLn(Format('Local variables (%d):', [Length(LVariables)]));
    for LVar in LVariables do
    begin
      if LVar.VarType <> '' then
        TUtils.PrintLn(Format('  %s (%s) = %s', [LVar.VarName, LVar.VarType, LVar.Value]))
      else
        TUtils.PrintLn(Format('  %s = %s', [LVar.VarName, LVar.Value]));
    end;
  end;
end;

procedure TDebugREPL.HandlePrint(const ACommand: string);
var
  LExpr: string;
  LStack: TArray<TStackFrame>;
  LResult: string;
begin
  if FDebugger.State <> dsStopped then
  begin
    TUtils.PrintLn(COLOR_RED + 'Not stopped' + COLOR_RESET);
    Exit;
  end;

  LExpr := Trim(Copy(ACommand, 3, MaxInt));
  if LExpr <> '' then
  begin
    // Get current frame ID from stack
    LStack := FDebugger.GetCallStack(FDebugger.CurrentThreadID);
    if Length(LStack) > 0 then
    begin
      if FDebugger.EvaluateExpression(LExpr, LStack[0].ID, LResult) then
        TUtils.PrintLn(LResult)
      else
        TUtils.PrintLn(COLOR_RED + 'Evaluation failed: ' + FDebugger.GetLastError() + COLOR_RESET);
    end
    else
      TUtils.PrintLn(COLOR_RED + 'No stack frames available' + COLOR_RESET);
  end;
end;

procedure TDebugREPL.HandleContinue();
var
  LSourceContext: string;
begin
  if FDebugger.State <> dsStopped then
  begin
    TUtils.PrintLn(COLOR_RED + 'Not stopped' + COLOR_RESET);
    Exit;
  end;

  TUtils.PrintLn('Continuing...');
  if FDebugger.ContinueExecution() then
  begin
    FDebugger.ProcessPendingEvents(5000);
    if FDebugger.State = dsStopped then
    begin
      TUtils.PrintLn(COLOR_GREEN + 'Stopped again' + COLOR_RESET);
      LSourceContext := FDebugger.GetSourceContext();
      if LSourceContext <> '' then
        TUtils.PrintLn(LSourceContext);
    end
    else if FDebugger.State = dsExited then
      TUtils.PrintLn(COLOR_YELLOW + 'Program exited' + COLOR_RESET);
  end
  else
    TUtils.PrintLn(COLOR_RED + 'Failed: ' + FDebugger.GetLastError() + COLOR_RESET);
end;

procedure TDebugREPL.HandleNext();
var
  LSourceContext: string;
begin
  if FDebugger.State <> dsStopped then
  begin
    TUtils.PrintLn(COLOR_RED + 'Not stopped' + COLOR_RESET);
    Exit;
  end;

  TUtils.PrintLn('Stepping over...');
  if FDebugger.StepOver() then
  begin
    FDebugger.ProcessPendingEvents(2000);
    TUtils.PrintLn(COLOR_GREEN + 'Step complete' + COLOR_RESET);
    
    if FDebugger.State = dsStopped then
    begin
      LSourceContext := FDebugger.GetSourceContext();
      if LSourceContext <> '' then
        TUtils.PrintLn(LSourceContext);
    end
    else if FDebugger.State = dsExited then
      TUtils.PrintLn(COLOR_YELLOW + 'Program exited' + COLOR_RESET);
  end
  else
    TUtils.PrintLn(COLOR_RED + 'Failed: ' + FDebugger.GetLastError() + COLOR_RESET);
end;

procedure TDebugREPL.HandleStepInto();
var
  LSourceContext: string;
begin
  if FDebugger.State <> dsStopped then
  begin
    TUtils.PrintLn(COLOR_RED + 'Not stopped' + COLOR_RESET);
    Exit;
  end;

  TUtils.PrintLn('Stepping into...');
  if FDebugger.StepInto() then
  begin
    FDebugger.ProcessPendingEvents(2000);
    TUtils.PrintLn(COLOR_GREEN + 'Step complete' + COLOR_RESET);
    
    if FDebugger.State = dsStopped then
    begin
      LSourceContext := FDebugger.GetSourceContext();
      if LSourceContext <> '' then
        TUtils.PrintLn(LSourceContext);
    end
    else if FDebugger.State = dsExited then
      TUtils.PrintLn(COLOR_YELLOW + 'Program exited' + COLOR_RESET);
  end
  else
    TUtils.PrintLn(COLOR_RED + 'Failed: ' + FDebugger.GetLastError() + COLOR_RESET);
end;

procedure TDebugREPL.HandleStepOut();
var
  LSourceContext: string;
begin
  if FDebugger.State <> dsStopped then
  begin
    TUtils.PrintLn(COLOR_RED + 'Not stopped' + COLOR_RESET);
    Exit;
  end;

  TUtils.PrintLn('Stepping out...');
  if FDebugger.StepOut() then
  begin
    FDebugger.ProcessPendingEvents(2000);
    TUtils.PrintLn(COLOR_GREEN + 'Step complete' + COLOR_RESET);
    
    if FDebugger.State = dsStopped then
    begin
      LSourceContext := FDebugger.GetSourceContext();
      if LSourceContext <> '' then
        TUtils.PrintLn(LSourceContext);
    end
    else if FDebugger.State = dsExited then
      TUtils.PrintLn(COLOR_YELLOW + 'Program exited' + COLOR_RESET);
  end
  else
    TUtils.PrintLn(COLOR_RED + 'Failed: ' + FDebugger.GetLastError() + COLOR_RESET);
end;

procedure TDebugREPL.HandleRestart();
var
  LAllBreakpoints: TArray<TBreakpoint>;
  LI: Integer;
  LSourceContext: string;
  LBreakpointsByFile: TDictionary<string, TList<Integer>>;
  LLinesList: TList<Integer>;
  LLinesArray: TArray<Integer>;
  LKey: string;
  LLine: Integer;
begin
  TUtils.PrintLn('Restarting program...');

  // Get current breakpoints BEFORE resetting
  LAllBreakpoints := FDebugger.GetAllBreakpoints();
  TUtils.PrintLn(Format('Found %d breakpoint(s) to restore', [Length(LAllBreakpoints)]));

  // Always do a full DAP session restart for consistency
  if FDebugger.State in [dsLaunched, dsRunning, dsStopped] then
  begin
    TUtils.PrintLn('Disconnecting from current session...');
    FDebugger.Disconnect();
    FDebugger.ProcessPendingEvents(500);
  end;

  // Stop and restart the DAP process
  TUtils.PrintLn('Restarting DAP session...');
  FDebugger.Stop();
  
  if not FDebugger.Start() then
  begin
    TUtils.PrintLn(COLOR_RED + 'Failed to restart DAP: ' + FDebugger.GetLastError() + COLOR_RESET);
    Exit;
  end;
  
  if not FDebugger.Initialize() then
  begin
    TUtils.PrintLn(COLOR_RED + 'Failed to initialize DAP: ' + FDebugger.GetLastError() + COLOR_RESET);
    Exit;
  end;

  // Relaunch the same executable
  if not FDebugger.Launch(FExePath) then
  begin
    TUtils.PrintLn(COLOR_RED + 'Launch failed: ' + FDebugger.GetLastError() + COLOR_RESET);
    Exit;
  end;

  // Wait for "initialized" event
  FDebugger.ProcessPendingEvents(2000);

  // Re-set all breakpoints (after initialized event)
  if Length(LAllBreakpoints) > 0 then
  begin
    TUtils.PrintLn('Restoring breakpoints...');
    
    // Group breakpoints by file (same approach as LoadBreakpointsFromFile)
    LBreakpointsByFile := TDictionary<string, TList<Integer>>.Create();
    try
      for LI := 0 to High(LAllBreakpoints) do
      begin
        if not LBreakpointsByFile.ContainsKey(LAllBreakpoints[LI].FileName) then
          LBreakpointsByFile.Add(LAllBreakpoints[LI].FileName, TList<Integer>.Create());
        
        LBreakpointsByFile[LAllBreakpoints[LI].FileName].Add(LAllBreakpoints[LI].LineNumber);
      end;
      
      // Set breakpoints per file (ONE request per file with ALL lines)
      for LKey in LBreakpointsByFile.Keys do
      begin
        LLinesList := LBreakpointsByFile[LKey];
        LLinesArray := LLinesList.ToArray();
        
        if FDebugger.SetBreakpoints(LKey, LLinesArray) then
        begin
          for LLine in LLinesArray do
            TUtils.PrintLn(COLOR_GREEN + Format('  Breakpoint at line %d restored!', [LLine]) + COLOR_RESET);
        end
        else
          TUtils.PrintLn(COLOR_YELLOW + Format('  Warning: Could not restore breakpoints for %s',
            [ExtractFileName(LKey)]) + COLOR_RESET);
      end;
    finally
      // Free all lists in dictionary
      for LLinesList in LBreakpointsByFile.Values do
        LLinesList.Free();
      LBreakpointsByFile.Free();
    end;
  end;

  // ConfigurationDone to start execution
  if not FDebugger.ConfigurationDone() then
  begin
    TUtils.PrintLn(COLOR_RED + 'ConfigurationDone failed: ' + FDebugger.GetLastError() + COLOR_RESET);
    Exit;
  end;

  TUtils.PrintLn(COLOR_GREEN + 'Program restarted!' + COLOR_RESET);

  // Wait for breakpoint or run to completion
  FDebugger.ProcessPendingEvents(5000);

  if FDebugger.State = dsStopped then
  begin
    LSourceContext := FDebugger.GetSourceContext();
    if LSourceContext <> '' then
      TUtils.PrintLn(LSourceContext);
  end
  else if FDebugger.State = dsExited then
    TUtils.PrintLn(COLOR_YELLOW + 'Program exited' + COLOR_RESET);
end;

procedure TDebugREPL.HandleFile(const ACommand: string);
begin
  FExePath := Trim(Copy(ACommand, 6, MaxInt));

  if not TFile.Exists(FExePath) then
  begin
    TUtils.PrintLn(COLOR_RED + 'File not found: ' + FExePath + COLOR_RESET);
    Exit;
  end;

  // Clear breakpoints when switching to a new executable
  if FDebugger.ClearAllBreakpoints() then
    TUtils.PrintLn('Cleared previous breakpoints');

  TUtils.PrintLn(COLOR_GREEN + 'Loaded: ' + FExePath + COLOR_RESET);
  TUtils.PrintLn('Use ''r'' to run the program.');
end;

procedure TDebugREPL.HandleVerbose(const ACommand: string);
begin
  if ACommand = 'verbose on' then
  begin
    FDebugger.VerboseLogging := True;
    TUtils.PrintLn(COLOR_GREEN + 'Verbose logging enabled' + COLOR_RESET);
  end
  else if ACommand = 'verbose off' then
  begin
    FDebugger.VerboseLogging := False;
    TUtils.PrintLn(COLOR_GREEN + 'Verbose logging disabled' + COLOR_RESET);
  end;
end;

procedure TDebugREPL.ProcessCommand(const ACommand: string);
begin
  if ACommand = '' then
    Exit;

  // Process commands
  if ACommand = 'quit' then
  begin
    FRunning := False;
  end
  else if (ACommand = 'h') or (ACommand = 'help') then
  begin
    ShowHelp();
  end
  else if ACommand.StartsWith('b ') then
  begin
    HandleSetBreakpoint(ACommand);
  end
  else if ACommand = 'bl' then
  begin
    HandleListBreakpoints();
  end
  else if ACommand.StartsWith('bd ') then
  begin
    HandleDeleteBreakpoint(ACommand);
  end
  else if ACommand = 'bc' then
  begin
    HandleClearBreakpoints();
  end
  else if ACommand.StartsWith('verbose ') then
  begin
    HandleVerbose(ACommand);
  end
  else if ACommand = 'threads' then
  begin
    HandleThreads();
  end
  else if ACommand = 'bt' then
  begin
    HandleBacktrace();
  end
  else if ACommand = 'locals' then
  begin
    HandleLocals();
  end
  else if ACommand.StartsWith('p ') then
  begin
    HandlePrint(ACommand);
  end
  else if ACommand = 'c' then
  begin
    HandleContinue();
  end
  else if ACommand = 'n' then
  begin
    HandleNext();
  end
  else if ACommand = 's' then
  begin
    HandleStepInto();
  end
  else if ACommand = 'finish' then
  begin
    HandleStepOut();
  end
  else if ACommand = 'r' then
  begin
    HandleRestart();
  end
  else if ACommand.StartsWith('file ') then
  begin
    HandleFile(ACommand);
  end
  else
  begin
    TUtils.PrintLn(COLOR_RED + 'Unknown command: ' + ACommand + COLOR_RESET);
  end;
end;

procedure TDebugREPL.Run(const AExePath: string; const APasFile: string);
var
  LCommand: string;
  LSourceContext: string;
  LBreakpointFile: string;
begin
  if not Assigned(FDebugger) then
  begin
    TUtils.PrintLn(COLOR_RED + 'Error: No debugger assigned to REPL' + COLOR_RESET);
    Exit;
  end;

  FExePath := AExePath;
  FPasFile := APasFile;

  if not TFile.Exists(FExePath) then
  begin
    TUtils.PrintLn(COLOR_YELLOW + 'Executable not found: ' + FExePath + COLOR_RESET);
    Exit;
  end;

  // Launch first
  TUtils.PrintLn('Launching program...');
  if not FDebugger.Launch(FExePath) then
  begin
    TUtils.PrintLn(COLOR_RED + 'Failed to launch: ' + FDebugger.GetLastError() + COLOR_RESET);
    Exit;
  end;

  TUtils.PrintLn(COLOR_GREEN + 'Launched!' + COLOR_RESET);
  TUtils.PrintLn();

  // Wait for "initialized" event after launch
  TUtils.PrintLn('Waiting for initialized event...');
  FDebugger.ProcessPendingEvents(2000);
  TUtils.PrintLn();

  // Load breakpoints from file if it exists
  LBreakpointFile := TPath.ChangeExtension(FExePath, '.breakpoints');
  if TFile.Exists(LBreakpointFile) then
  begin
    TUtils.PrintLn('Loading breakpoints from file...');
    FDebugger.LoadBreakpointsFromFile(LBreakpointFile);
    TUtils.PrintLn();
  end;

  // Configuration done - this starts execution
  TUtils.PrintLn('Sending configurationDone...');
  if not FDebugger.ConfigurationDone() then
  begin
    TUtils.PrintLn(COLOR_RED + 'Failed: ' + FDebugger.GetLastError() + COLOR_RESET);
    Exit;
  end;

  TUtils.PrintLn(COLOR_GREEN + 'Running...' + COLOR_RESET);
  TUtils.PrintLn();

  // Wait for breakpoint
  TUtils.PrintLn('Waiting for breakpoint...');
  FDebugger.ProcessPendingEvents(5000);
  TUtils.PrintLn();

  // REPL loop
  if FDebugger.State = dsStopped then
  begin
    LSourceContext := FDebugger.GetSourceContext();
    if LSourceContext <> '' then
    begin
      TUtils.PrintLn(LSourceContext);
      TUtils.PrintLn();
    end;

    TUtils.PrintLn(COLOR_CYAN + '=== INTERACTIVE REPL ===' + COLOR_RESET);
    ShowHelp();
    TUtils.PrintLn();

    FRunning := True;
    while FRunning do
    begin
      // Show prompt
      Write(FPrompt);
      ReadLn(LCommand);
      LCommand := Trim(LCommand);

      ProcessCommand(LCommand);
    end;
  end
  else
  begin
    TUtils.PrintLn(COLOR_YELLOW + 'Program did not stop at breakpoint' + COLOR_RESET);
  end;

  TUtils.PrintLn();
  TUtils.PrintLn(COLOR_GREEN + 'REPL session complete!' + COLOR_RESET);
end;

procedure TDebugREPL.Stop();
begin
  FRunning := False;
end;

end.
