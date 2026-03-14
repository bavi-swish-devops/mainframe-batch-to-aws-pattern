      ******************************************************************
      * PROGRAM-ID : ACCTPOST
      * TYPE       : BATCH
      * PURPOSE    : Read fixed-width transaction file, summarize
      *              credits and debits, and display batch totals.
      *
      * INPUT      : legacy/data/input_fixed.dat (LINE SEQUENTIAL)
      *              Layout:
      *              ACCOUNT-ID  (1-10)
      *              TXN-DATE   (11-18)  YYYYMMDD
      *              AMOUNT     (19-27)  9(9) implied 2 decimals
      *              TXN-TYPE   (28-28)  C=Credit / D=Debit
      *              DESC       (29-48)
      *
      * OUTPUT     : Console summary
      *
      * AUTHOR     : Eduardo Dias Gusmao
      * CREATED    : 2026-03-13
      *
      * CHANGE LOG :
      * - 2026-03-13 EDG - Initial version
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. ACCTPOST.

      *-----------------------------------------------------------------
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
      *-----------------------------------------------------------------
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IN-FILE
               ASSIGN TO 'legacy/data/input_fixed.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-IN-FILE-STATUS.

      *-----------------------------------------------------------------
       DATA DIVISION.
       FILE SECTION.
      *-----------------------------------------------------------------
       FD  IN-FILE.
       01  IN-RAW-REC                       PIC X(256).

       01  WS-IN-RAW-REC                    PIC X(256) VALUE SPACES.

       WORKING-STORAGE SECTION.
      *-----------------------------------------------------------------

       01  WS-IN-REC.
           03 WS-ACCOUNT-ID                 PIC X(010) VALUE SPACES.
           03 WS-TXN-DATE                   PIC X(008) VALUE SPACES.
           03 WS-AMOUNT-TEXT                PIC X(009) VALUE SPACES.
           03 WS-TXN-TYPE                   PIC X(001) VALUE SPACES.
           03 WS-DESCRIPTION                PIC X(020) VALUE SPACES.

       01  WS-EOF-FLAG                      PIC X VALUE 'N'.
           88 WS-EOF                        VALUE 'Y'.
           88 WS-NOT-EOF                    VALUE 'N'.

       01  WS-IN-FILE-STATUS                PIC X(02) VALUE SPACES.
           88 WS-IN-OK                      VALUE '00'.

       01  PSC-ERRO-PGM                     PIC 9(04) VALUE ZEROS.

       01  WS-COUNTERS.
           03 WS-RECORDS-READ               PIC 9(009) VALUE ZEROS.

       01  WS-TOTALS.
           03 WS-TOTAL-CREDITS              PIC 9(011) VALUE ZEROS.
           03 WS-TOTAL-DEBITS               PIC 9(011) VALUE ZEROS.
           03 WS-NET-AMOUNT                 PIC S9(011) VALUE ZEROS.

       01  WS-WORK-FIELDS.
           03 WS-AMOUNT-NUM                 PIC 9(009) VALUE ZEROS.
           03 WS-AMOUNT-DISPLAY             PIC 9(009)V99 VALUE ZEROS.

       01  WS-DISPLAY-FIELDS.
           03 WS-DSP-RECORDS-READ           PIC Z,ZZZ,ZZ9.
           03 WS-DSP-TOTAL-CREDITS          PIC Z,ZZZ,ZZ9.99.
           03 WS-DSP-TOTAL-DEBITS           PIC Z,ZZZ,ZZ9.99.
           03 WS-DSP-NET-AMOUNT             PIC -Z,ZZZ,ZZ9.99.

       01  WS-ABEND-MSG                     PIC X(080) VALUE SPACES.

       PROCEDURE DIVISION.
      *-----------------------------------------------------------------
       000000-MAIN SECTION.
      *-----------------------------------------------------------------
           MOVE 0001 TO PSC-ERRO-PGM

           PERFORM 100000-OPEN-FILES
           PERFORM 200000-PROCESS-FILES
           PERFORM 900000-CLOSE-FILES

           STOP RUN
           .
       000999-EXIT-MAIN.
           EXIT.

      *-----------------------------------------------------------------
       100000-OPEN-FILES SECTION.
      *-----------------------------------------------------------------
           MOVE 0002 TO PSC-ERRO-PGM

           OPEN INPUT IN-FILE

           IF NOT WS-IN-OK
               MOVE 'FAILED TO OPEN INPUT FILE' TO WS-ABEND-MSG
               PERFORM 999900-ABEND
           END-IF
           .
       100999-EXIT-OPEN-FILES.
           EXIT.

      *-----------------------------------------------------------------
       200000-PROCESS-FILES SECTION.
      *-----------------------------------------------------------------
           MOVE 0003 TO PSC-ERRO-PGM

           PERFORM 210000-READ-IN-FILE

           PERFORM UNTIL WS-EOF
               PERFORM 300000-PROCESS-RECORD
               PERFORM 210000-READ-IN-FILE
           END-PERFORM

           PERFORM 800000-DISPLAY-SUMMARY
           .
       200999-EXIT-PROCESS-FILES.
           EXIT.

      *-----------------------------------------------------------------
       210000-READ-IN-FILE SECTION.
      *-----------------------------------------------------------------
           MOVE 0004 TO PSC-ERRO-PGM

           READ IN-FILE INTO WS-IN-RAW-REC
               AT END
                   SET WS-EOF TO TRUE
               NOT AT END
                   IF NOT WS-IN-OK
                       MOVE 'FAILED TO READ INPUT FILE' TO WS-ABEND-MSG
                       PERFORM 999900-ABEND
                   END-IF
                   PERFORM 220000-PARSE-IN-REC
           END-READ
           .
       210999-EXIT-READ-IN-FILE.
           EXIT.

      *-----------------------------------------------------------------
       220000-PARSE-IN-REC SECTION.
      *-----------------------------------------------------------------
           MOVE 0010 TO PSC-ERRO-PGM

           MOVE WS-IN-RAW-REC(01:10) TO WS-ACCOUNT-ID
           MOVE WS-IN-RAW-REC(11:08) TO WS-TXN-DATE
           MOVE WS-IN-RAW-REC(19:09) TO WS-AMOUNT-TEXT
           MOVE WS-IN-RAW-REC(28:01) TO WS-TXN-TYPE
           MOVE WS-IN-RAW-REC(29:20) TO WS-DESCRIPTION
           .
       220999-EXIT-PARSE-IN-REC.
           EXIT.

      *-----------------------------------------------------------------
       300000-PROCESS-RECORD SECTION.
      *-----------------------------------------------------------------
           MOVE 0005 TO PSC-ERRO-PGM

           ADD 1 TO WS-RECORDS-READ

           PERFORM 310000-VALIDATE-RECORD
           PERFORM 320000-ACCUMULATE-AMOUNTS
           .
       300999-EXIT-PROCESS-RECORD.
           EXIT.

      *-----------------------------------------------------------------
       310000-VALIDATE-RECORD SECTION.
      *-----------------------------------------------------------------
           MOVE 0006 TO PSC-ERRO-PGM

           IF WS-TXN-TYPE NOT = 'C'
           AND WS-TXN-TYPE NOT = 'D'
               MOVE 'INVALID TRANSACTION TYPE' TO WS-ABEND-MSG
               PERFORM 999900-ABEND
           END-IF

           IF WS-AMOUNT-TEXT NUMERIC
               MOVE WS-AMOUNT-TEXT TO WS-AMOUNT-NUM
           ELSE
               MOVE 'INVALID AMOUNT FIELD' TO WS-ABEND-MSG
               PERFORM 999900-ABEND
           END-IF
           .
       310999-EXIT-VALIDATE-RECORD.
           EXIT.

      *-----------------------------------------------------------------
       320000-ACCUMULATE-AMOUNTS SECTION.
      *-----------------------------------------------------------------
           MOVE 0007 TO PSC-ERRO-PGM

           IF WS-TXN-TYPE = 'C'
               ADD WS-AMOUNT-NUM TO WS-TOTAL-CREDITS
               ADD WS-AMOUNT-NUM TO WS-NET-AMOUNT
           ELSE
               ADD WS-AMOUNT-NUM TO WS-TOTAL-DEBITS
               SUBTRACT WS-AMOUNT-NUM FROM WS-NET-AMOUNT
           END-IF
           .
       320999-EXIT-ACCUMULATE-AMOUNTS.
           EXIT.

      *-----------------------------------------------------------------
       800000-DISPLAY-SUMMARY SECTION.
      *-----------------------------------------------------------------
           MOVE 0008 TO PSC-ERRO-PGM

           MOVE WS-RECORDS-READ TO WS-DSP-RECORDS-READ

           COMPUTE WS-AMOUNT-DISPLAY = WS-TOTAL-CREDITS / 100
           MOVE WS-AMOUNT-DISPLAY TO WS-DSP-TOTAL-CREDITS

           COMPUTE WS-AMOUNT-DISPLAY = WS-TOTAL-DEBITS / 100
           MOVE WS-AMOUNT-DISPLAY TO WS-DSP-TOTAL-DEBITS

           COMPUTE WS-AMOUNT-DISPLAY = WS-NET-AMOUNT / 100
           MOVE WS-AMOUNT-DISPLAY TO WS-DSP-NET-AMOUNT

           DISPLAY '=============================================='
           DISPLAY 'ACCTPOST BATCH SUMMARY'
           DISPLAY '=============================================='
           DISPLAY 'RECORDS READ   : ' WS-DSP-RECORDS-READ
           DISPLAY 'TOTAL CREDITS  : ' WS-DSP-TOTAL-CREDITS
           DISPLAY 'TOTAL DEBITS   : ' WS-DSP-TOTAL-DEBITS
           DISPLAY 'NET AMOUNT     : ' WS-DSP-NET-AMOUNT
           DISPLAY '=============================================='
           .
       800999-EXIT-DISPLAY-SUMMARY.
           EXIT.

      *-----------------------------------------------------------------
       900000-CLOSE-FILES SECTION.
      *-----------------------------------------------------------------
           MOVE 0009 TO PSC-ERRO-PGM

           CLOSE IN-FILE
           .
       900999-EXIT-CLOSE-FILES.
           EXIT.

      *-----------------------------------------------------------------
       999900-ABEND SECTION.
      *-----------------------------------------------------------------
           DISPLAY 'ABEND - PSC=' PSC-ERRO-PGM
                   ' FS-IN=' WS-IN-FILE-STATUS
                   ' MSG=' WS-ABEND-MSG
           STOP RUN
           .
       999999-EXIT-ABEND.
           EXIT.
