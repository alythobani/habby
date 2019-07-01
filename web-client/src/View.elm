module View exposing (view)

import Array
import Browser
import DefaultServices.Keyboard as Keyboard
import DefaultServices.Util as Util
import Dict
import HabitUtil
import Html exposing (Html, button, div, hr, i, input, span, text, textarea)
import Html.Attributes exposing (class, classList, id, placeholder, tabindex, type_, value)
import Html.Events exposing (onClick, onInput, onMouseEnter, onMouseLeave)
import Maybe.Extra as Maybe
import Model exposing (Model)
import Models.ApiError as ApiError
import Models.DialogScreen as DialogScreen
import Models.FrequencyStats as FrequencyStats
import Models.Habit as Habit
import Models.HabitData as HabitData
import Models.HabitDayNote as HabitDayNote
import Models.YmdDate as YmdDate
import Msg exposing (Msg(..))
import RemoteData


view : Model -> Browser.Document Msg
view model =
    { title = "Stay Habby"
    , body =
        [ div
            [ classList [ ( "view", True ), ( "dark-mode", model.darkModeOn ) ] ]
            [ div
                [ class "panels-container" ]
                [ renderTopPanel
                    model.selectedYmd
                    model.actualYmd
                    model.darkModeOn
                    model.errorMessage
                    model.openTopPanelDateDropdown
                , renderHabitsPanel
                    model.selectedYmd
                    model.actualYmd
                    model.allHabits
                    model.allHabitData
                    model.allFrequencyStats
                    model.editingHabitAmountDict
                    model.habitActionsDropdown
                , renderAddHabitForm
                    model.addHabit
                ]
            , renderDialogBackgroundScreen model.activeDialogScreen
            , renderChooseDateDialog
                model.activeDialogScreen
                model.chooseDateDialogChosenYmd
                model.actualYmd
            , renderSetHabitDataShortcutHabitSelectionScreen
                model.activeDialogScreen
                model.setHabitDataShortcutHabitNameFilterText
                model.setHabitDataShortcutFilteredHabits
                model.setHabitDataShortcutSelectedHabitIndex
            , renderSetHabitDataShortcutAmountScreen
                model.activeDialogScreen
                model.allHabitData
                model.setHabitDataShortcutAmountScreenHabit
                model.setHabitDataShortcutAmountScreenInputInt
                model.selectedYmd
            , renderEditGoalDialog
                model.activeDialogScreen
                model.editGoalDialogHabit
                model.editGoal
                model.actualYmd
            , renderErrorMessage
                model.errorMessage
                model.activeDialogScreen
            , renderAddNoteHabitSelectionScreen
                model.activeDialogScreen
                model.addNoteHabitSelectionFilterText
                model.addNoteHabitSelectionFilteredHabits
                model.addNoteHabitSelectionSelectedHabitIndex
            , renderAddNoteDialog
                model.activeDialogScreen
                model.addNoteDialogHabit
                model.addNoteDialogInput
                model.selectedYmd
                model.allHabitDayNotes
            , renderSuspendOrResumeHabitSelectionScreen
                model.activeDialogScreen
                model.suspendOrResumeHabitSelectionFilterText
                model.suspendOrResumeHabitSelectionFilteredHabits
                model.suspendOrResumeHabitSelectionSelectedHabitIndex
            ]
        ]
    }


{-| An `Html.textarea` element that stops propagation of any `keydown` events within it.

Useful for creating `textarea` elements for the user to type into without triggering any
global keyboard shortcuts.

-}
textareaStopKeydownPropagation : List (Html.Attribute Msg) -> List (Html Msg) -> Html Msg
textareaStopKeydownPropagation attrs htmls =
    let
        stopPropagationAttrs : List (Html.Attribute Msg)
        stopPropagationAttrs =
            Util.onKeydownStopPropagation (\keyKeyboard -> Just NoOp) :: attrs
    in
    textarea stopPropagationAttrs htmls


{-| An `Html.input` element that stops propagation of any `keydown` events within it.

Useful for creating `input` elements for the user to type into without triggering any
global keyboard shortcuts.

-}
inputStopKeydownPropagation : List (Html.Attribute Msg) -> List (Html Msg) -> Html Msg
inputStopKeydownPropagation attrs htmls =
    let
        stopPropagationAttrs : List (Html.Attribute Msg)
        stopPropagationAttrs =
            Util.onKeydownStopPropagation (\keyKeyboard -> Just NoOp) :: attrs
    in
    input stopPropagationAttrs htmls


renderTopPanel :
    Maybe YmdDate.YmdDate
    -> Maybe YmdDate.YmdDate
    -> Bool
    -> Maybe String
    -> Bool
    -> Html Msg
renderTopPanel maybeSelectedYmd maybeActualYmd darkModeOn errorMessage openDateDropdown =
    let
        topPanelTitleText : String
        topPanelTitleText =
            case ( maybeSelectedYmd, maybeActualYmd ) of
                ( Just selectedYmd, Just actualYmd ) ->
                    if selectedYmd == actualYmd then
                        "Today's Progress"

                    else if selectedYmd == YmdDate.addDays 1 actualYmd then
                        "Tomorrow's Progress"

                    else if selectedYmd == YmdDate.addDays -1 actualYmd then
                        "Yesterday's Progress"

                    else if YmdDate.compareYmds selectedYmd actualYmd == LT then
                        "Past Progress"

                    else
                        "Future Progress"

                ( _, Nothing ) ->
                    -- We don't know the actual date
                    "..."

                ( Nothing, _ ) ->
                    "No Selected Date"
    in
    div
        [ class "top-panel" ]
        [ div [ class "top-panel-title" ] [ text topPanelTitleText ]
        , div
            [ classList
                [ ( "top-panel-error-message-icon", True )
                , ( "display-none", not <| Maybe.isJust errorMessage )
                ]
            , onClick OpenErrorMessageDialogScreen
            ]
            [ i [ class "material-icons" ] [] ]
        , div
            [ class "top-panel-dark-mode-switch"
            , onClick OnToggleDarkMode
            ]
            [ div
                [ classList
                    [ ( "top-panel-dark-mode-switch-toggler", True )
                    , ( "top-panel-dark-mode-switch-toggler-checked", darkModeOn )
                    ]
                ]
                [ span [ class "top-panel-dark-mode-switch-toggler-slider" ] [] ]
            , div
                [ class "top-panel-dark-mode-switch-text" ]
                [ text <|
                    if darkModeOn then
                        "Dark Mode"

                    else
                        "Light Mode"
                ]
            ]
        , div
            [ class "top-panel-date" ]
            [ text <|
                Maybe.withDefault
                    "..."
                    (Maybe.map YmdDate.prettyPrintWithWeekday maybeSelectedYmd)
            , div [ class "top-panel-date-dropdown" ]
                [ div
                    [ class <|
                        if openDateDropdown then
                            "top-panel-date-dropdown-toggler-full"

                        else
                            "top-panel-date-dropdown-toggler-default"
                    , onClick ToggleTopPanelDateDropdown
                    ]
                    [ text "" ]
                , div
                    [ class "top-panel-date-dropdown-buttons" ]
                    [ button
                        [ classList
                            [ ( "top-panel-date-dropdown-button", True )
                            , ( "display-none", not openDateDropdown )
                            ]
                        , onClick <| SetSelectedDateToXDaysFromToday 0
                        ]
                        [ text "Today" ]
                    , button
                        [ classList
                            [ ( "top-panel-date-dropdown-button", True )
                            , ( "display-none", not openDateDropdown )
                            ]
                        , onClick <| SetSelectedDateToXDaysFromToday -1
                        ]
                        [ text "Yesterday" ]
                    , button
                        [ classList
                            [ ( "top-panel-date-dropdown-button", True )
                            , ( "display-none", not openDateDropdown )
                            ]
                        , onClick <| SetSelectedDateToXDaysFromToday 1
                        ]
                        [ text "Tomorrow" ]
                    , button
                        [ classList
                            [ ( "top-panel-date-dropdown-button", True )
                            , ( "display-none", not openDateDropdown )
                            ]
                        , onClick OnChooseCustomDateClick
                        ]
                        [ text "Custom Date" ]
                    ]
                ]
            ]
        ]


renderHabitsPanel :
    Maybe YmdDate.YmdDate
    -> Maybe YmdDate.YmdDate
    -> RemoteData.RemoteData ApiError.ApiError (List Habit.Habit)
    -> RemoteData.RemoteData ApiError.ApiError (List HabitData.HabitData)
    -> RemoteData.RemoteData ApiError.ApiError (List FrequencyStats.FrequencyStats)
    -> Dict.Dict String Int
    -> Maybe String
    -> Html Msg
renderHabitsPanel maybeSelectedYmd maybeActualYmd rdHabits rdHabitData rdFrequencyStatsList editingHabitAmountDict habitActionsDropdown =
    div
        [ class "habits-panel" ]
        (case ( rdHabits, rdHabitData, ( maybeSelectedYmd, maybeActualYmd ) ) of
            ( RemoteData.Success habits, RemoteData.Success habitData, ( Just selectedYmd, Just actualYmd ) ) ->
                let
                    ( goodHabits, badHabits ) =
                        Habit.splitHabits habits

                    ( sortedGoodHabits, sortedBadHabits, sortedSuspendedHabits ) =
                        case rdFrequencyStatsList of
                            RemoteData.Success frequencyStatsList ->
                                let
                                    ( goodActiveHabits, badActiveHabits, suspendedHabits ) =
                                        HabitUtil.splitHabitsByCurrentlySuspended frequencyStatsList goodHabits badHabits
                                in
                                ( HabitUtil.sortHabitsByCurrentFragment frequencyStatsList goodActiveHabits
                                , HabitUtil.sortHabitsByCurrentFragment frequencyStatsList badActiveHabits
                                , HabitUtil.sortHabitsByCurrentFragment frequencyStatsList suspendedHabits
                                )

                            _ ->
                                ( goodHabits, badHabits, [] )

                    renderHabit habit =
                        renderHabitBox
                            (case rdFrequencyStatsList of
                                RemoteData.Success frequencyStatsList ->
                                    HabitUtil.findFrequencyStatsForHabit
                                        habit
                                        frequencyStatsList

                                _ ->
                                    Nothing
                            )
                            selectedYmd
                            actualYmd
                            habitData
                            editingHabitAmountDict
                            habitActionsDropdown
                            habit
                in
                if List.isEmpty habits then
                    [ div
                        [ class "habits-panel-empty-habby-message" ]
                        [ div
                            [ class "habits-panel-empty-habby-message-header" ]
                            [ text "Welcome to Habby!" ]
                        , div
                            [ class "habits-panel-empty-habby-message-body" ]
                            [ text "Start by adding a habit below." ]
                        ]
                    ]

                else
                    [ div
                        [ class "habit-list good-habits" ]
                        (List.map renderHabit sortedGoodHabits)
                    , div
                        [ class "habit-list bad-habits" ]
                        (List.map renderHabit sortedBadHabits)
                    , div
                        [ class "habit-list suspended-habits" ]
                        (List.map renderHabit sortedSuspendedHabits)
                    ]

            ( RemoteData.Failure apiError, _, _ ) ->
                [ span [ class "retrieving-habits-status" ] [ text "Failure..." ] ]

            ( _, RemoteData.Failure apiError, _ ) ->
                [ span [ class "retrieving-habits-status" ] [ text "Failure..." ] ]

            _ ->
                [ span [ class "retrieving-habits-status" ] [ text "Loading..." ] ]
        )


renderAddHabitForm : Habit.AddHabitInputData -> Html Msg
renderAddHabitForm addHabit =
    let
        maybeCreateHabitData =
            Habit.extractCreateHabit addHabit
    in
    div
        [ class "add-habit-form" ]
        [ div
            [ classList [ ( "add-habit-form-body", True ), ( "display-none", not addHabit.openView ) ] ]
            [ div
                [ class "add-habit-form-body-habit-tag-name" ]
                [ button
                    [ classList [ ( "selected", addHabit.kind == Habit.GoodHabitKind ) ]
                    , onClick <| OnSelectAddHabitKind Habit.GoodHabitKind
                    ]
                    [ text "Good Habit" ]
                , button
                    [ classList [ ( "selected", addHabit.kind == Habit.BadHabitKind ) ]
                    , onClick <| OnSelectAddHabitKind Habit.BadHabitKind
                    ]
                    [ text "Bad Habit" ]
                ]
            , div
                [ class "add-habit-form-body-name-and-description" ]
                [ inputStopKeydownPropagation
                    [ class "add-habit-form-body-name"
                    , placeholder "Name..."
                    , onInput OnAddHabitNameInput
                    , value addHabit.name
                    ]
                    []
                , textareaStopKeydownPropagation
                    [ class "add-habit-form-body-description"
                    , placeholder "Short description..."
                    , onInput OnAddHabitDescriptionInput
                    , value addHabit.description
                    ]
                    []
                ]
            , div
                [ classList
                    [ ( "add-habit-form-body-time-of-day", True )
                    , ( "display-none", addHabit.kind /= Habit.GoodHabitKind )
                    ]
                ]
                [ button
                    [ classList [ ( "habit-time-of-day", True ), ( "selected", addHabit.goodHabitTime == Habit.Anytime ) ]
                    , onClick <| OnSelectAddGoodHabitTime Habit.Anytime
                    ]
                    [ text "ANYTIME" ]
                , button
                    [ classList [ ( "habit-time-of-day", True ), ( "selected", addHabit.goodHabitTime == Habit.Morning ) ]
                    , onClick <| OnSelectAddGoodHabitTime Habit.Morning
                    ]
                    [ text "MORNING" ]
                , button
                    [ classList [ ( "habit-time-of-day", True ), ( "selected", addHabit.goodHabitTime == Habit.Evening ) ]
                    , onClick <| OnSelectAddGoodHabitTime Habit.Evening
                    ]
                    [ text "EVENING" ]
                ]
            , div
                [ class "add-habit-form-body-unit-name" ]
                [ inputStopKeydownPropagation
                    [ class "habit-unit-name-singular"
                    , placeholder "Unit name singular..."
                    , onInput OnAddHabitUnitNameSingularInput
                    , value addHabit.unitNameSingular
                    ]
                    []
                , inputStopKeydownPropagation
                    [ class "habit-unit-name-plural"
                    , placeholder "Unit name plural..."
                    , onInput OnAddHabitUnitNamePluralInput
                    , value addHabit.unitNamePlural
                    ]
                    []
                ]
            , div
                [ class "add-habit-form-body-frequency-tag-name" ]
                [ button
                    [ classList [ ( "selected", addHabit.frequencyKind == Habit.TotalWeekFrequencyKind ) ]
                    , onClick <| OnAddHabitSelectFrequencyKind Habit.TotalWeekFrequencyKind
                    ]
                    [ text "X Per Week" ]
                , button
                    [ classList [ ( "selected", addHabit.frequencyKind == Habit.SpecificDayOfWeekFrequencyKind ) ]
                    , onClick <| OnAddHabitSelectFrequencyKind Habit.SpecificDayOfWeekFrequencyKind
                    ]
                    [ text "Specific Days of Week" ]
                , button
                    [ classList [ ( "selected", addHabit.frequencyKind == Habit.EveryXDayFrequencyKind ) ]
                    , onClick <| OnAddHabitSelectFrequencyKind Habit.EveryXDayFrequencyKind
                    ]
                    [ text "Y Per X Days" ]
                ]
            , div
                [ classList
                    [ ( "add-habit-form-body-x-times-per-week", True )
                    , ( "display-none", addHabit.frequencyKind /= Habit.TotalWeekFrequencyKind )
                    ]
                ]
                [ inputStopKeydownPropagation
                    [ placeholder "X"
                    , onInput OnAddHabitTimesPerWeekInput
                    , value <| Maybe.withDefault "" (Maybe.map String.fromInt addHabit.timesPerWeek)
                    ]
                    []
                ]
            , div
                [ classList
                    [ ( "add-habit-form-body-specific-days-of-week", True )
                    , ( "display-none", addHabit.frequencyKind /= Habit.SpecificDayOfWeekFrequencyKind )
                    ]
                ]
                [ inputStopKeydownPropagation
                    [ placeholder "Monday"
                    , onInput OnAddHabitSpecificDayMondayInput
                    , value <| Maybe.withDefault "" (Maybe.map String.fromInt addHabit.mondayTimes)
                    ]
                    []
                , inputStopKeydownPropagation
                    [ placeholder "Tuesday"
                    , onInput OnAddHabitSpecificDayTuesdayInput
                    , value <| Maybe.withDefault "" (Maybe.map String.fromInt addHabit.tuesdayTimes)
                    ]
                    []
                , inputStopKeydownPropagation
                    [ placeholder "Wednesday"
                    , onInput OnAddHabitSpecificDayWednesdayInput
                    , value <| Maybe.withDefault "" (Maybe.map String.fromInt addHabit.wednesdayTimes)
                    ]
                    []
                , inputStopKeydownPropagation
                    [ placeholder "Thursday"
                    , onInput OnAddHabitSpecificDayThursdayInput
                    , value <| Maybe.withDefault "" (Maybe.map String.fromInt addHabit.thursdayTimes)
                    ]
                    []
                , inputStopKeydownPropagation
                    [ placeholder "Friday"
                    , onInput OnAddHabitSpecificDayFridayInput
                    , value <| Maybe.withDefault "" (Maybe.map String.fromInt addHabit.fridayTimes)
                    ]
                    []
                , inputStopKeydownPropagation
                    [ placeholder "Saturday"
                    , onInput OnAddHabitSpecificDaySaturdayInput
                    , value <| Maybe.withDefault "" (Maybe.map String.fromInt addHabit.saturdayTimes)
                    ]
                    []
                , inputStopKeydownPropagation
                    [ placeholder "Sunday"
                    , onInput OnAddHabitSpecificDaySundayInput
                    , value <| Maybe.withDefault "" (Maybe.map String.fromInt addHabit.sundayTimes)
                    ]
                    []
                ]
            , div
                [ classList
                    [ ( "add-habit-form-body-x-times-per-y-days", True )
                    , ( "display-none", addHabit.frequencyKind /= Habit.EveryXDayFrequencyKind )
                    ]
                ]
                [ inputStopKeydownPropagation
                    [ placeholder "Times"
                    , onInput OnAddHabitTimesInput
                    , value <| Maybe.withDefault "" (Maybe.map String.fromInt addHabit.times)
                    ]
                    []
                , inputStopKeydownPropagation
                    [ placeholder "Days"
                    , onInput OnAddHabitDaysInput
                    , value <| Maybe.withDefault "" (Maybe.map String.fromInt addHabit.days)
                    ]
                    []
                ]
            , case maybeCreateHabitData of
                Nothing ->
                    Util.hiddenDiv

                Just createHabitData ->
                    button
                        [ class "add-habit-form-submit-button"
                        , onClick <| AddHabit createHabitData
                        ]
                        [ text "Create Habit" ]
            ]
        , button
            [ class "add-habit-form-button"
            , onClick <|
                if addHabit.openView then
                    OnCancelAddHabit

                else
                    OnOpenAddHabit
            ]
            [ text <|
                if addHabit.openView then
                    "Cancel"

                else
                    "Add Habit"
            ]
        ]


habitActionsDropdownDiv :
    Bool
    -> YmdDate.YmdDate
    -> YmdDate.YmdDate
    -> Habit.Habit
    -> List Habit.SuspendedInterval
    -> Html Msg
habitActionsDropdownDiv dropdown selectedYmd actualYmd habit suspensions =
    let
        onToday : Bool
        onToday =
            selectedYmd == actualYmd

        suspensionsArray =
            Array.fromList suspensions

        currentSuspendedIntervalWithIndex : Maybe ( Int, Habit.SuspendedInterval )
        currentSuspendedIntervalWithIndex =
            Util.firstInstanceInArray suspensionsArray
                (\interval -> YmdDate.withinYmdDateInterval interval.startDate interval.endDate selectedYmd)

        currentlySuspended : Bool
        currentlySuspended =
            Maybe.isJust currentSuspendedIntervalWithIndex

        habitRecord =
            Habit.getCommonFields habit
    in
    div [ class "actions-dropdown" ]
        [ div
            [ class <|
                if dropdown then
                    "actions-dropdown-toggler-full"

                else
                    "actions-dropdown-toggler-default"
            , onClick <| ToggleHabitActionsDropdown habitRecord.id
            ]
            [ text "" ]
        , div
            [ classList
                [ ( "action-buttons", True )
                , ( "display-none", not dropdown )
                ]
            ]
            [ button
                [ class "action-button"
                , onClick <| OnResumeOrSuspendHabitClick habitRecord.id currentSuspendedIntervalWithIndex suspensionsArray selectedYmd
                ]
                [ text <|
                    if currentlySuspended then
                        "Resume"

                    else
                        "Suspend"
                ]
            , button
                [ classList
                    [ ( "action-button", True )

                    -- Don't allow user to edit a habit's goal unless they're looking at today
                    , ( "display-none", not onToday )
                    ]
                , onClick <| OnEditGoalClick habitRecord.id
                ]
                [ text "Edit Goal" ]
            , button
                [ class "action-button"
                , onClick <| OpenAddNoteDialog habit
                ]
                [ text "Add Note" ]
            ]
        ]


{-| Renders a habit box with the habit data loaded for that particular date.

Requires 2 event handlers, 1 for handling when data is input into the habit box and 1 for when the user wants to
update the habit data.

-}
renderHabitBox :
    Maybe FrequencyStats.FrequencyStats
    -> YmdDate.YmdDate
    -> YmdDate.YmdDate
    -> List HabitData.HabitData
    -> Dict.Dict String Int
    -> Maybe String
    -> Habit.Habit
    -> Html Msg
renderHabitBox habitStats selectedYmd actualYmd habitData editingHabitAmountDict habitActionsDropdown habit =
    let
        habitRecord =
            Habit.getCommonFields habit

        habitDatum =
            List.filter (\{ habitId, date } -> habitId == habitRecord.id && date == selectedYmd) habitData
                |> List.head
                |> (\maybeHabitDatum ->
                        case maybeHabitDatum of
                            Nothing ->
                                0

                            Just { amount } ->
                                amount
                   )

        editingHabitAmount =
            Dict.get habitRecord.id editingHabitAmountDict

        actionsDropdown =
            habitActionsDropdown == Just habitRecord.id

        isCurrentFragmentSuccessful =
            case habitStats of
                Nothing ->
                    False

                Just stats ->
                    HabitUtil.isHabitCurrentFragmentSuccessful habit stats

        frequencyStatisticDiv str =
            div
                [ class "frequency-statistic" ]
                [ text str ]
    in
    div
        [ class
            (if isCurrentFragmentSuccessful then
                "habit-success"

             else
                "habit-failure"
            )
        ]
        [ div [ class "habit-name" ] [ text habitRecord.name ]
        , habitActionsDropdownDiv actionsDropdown selectedYmd actualYmd habit habitRecord.suspensions
        , case habitStats of
            Nothing ->
                div
                    [ class "frequency-stats-list" ]
                    [ frequencyStatisticDiv "Loading..." ]

            Just stats ->
                if not stats.habitHasStarted then
                    div [ class "start-this-habit-message" ] [ text "Start this habit!" ]

                else
                    div [ class "frequency-stats-list" ]
                        [ div
                            [ class "current-progress" ]
                            [ text <|
                                String.fromInt stats.currentFragmentTotal
                                    ++ " out of "
                                    ++ String.fromInt stats.currentFragmentGoal
                                    ++ " "
                                    ++ habitRecord.unitNamePlural
                            ]
                        , frequencyStatisticDiv ("Days left: " ++ String.fromInt stats.currentFragmentDaysLeft)
                        , frequencyStatisticDiv
                            ((String.fromInt <|
                                round <|
                                    toFloat stats.successfulFragments
                                        * 100
                                        / toFloat stats.totalFragments
                             )
                                ++ "%"
                            )
                        , frequencyStatisticDiv ("Streak: " ++ String.fromInt stats.currentFragmentStreak)
                        , frequencyStatisticDiv ("Best streak: " ++ String.fromInt stats.bestFragmentStreak)
                        , frequencyStatisticDiv ("Total done: " ++ String.fromInt stats.totalDone)
                        ]
        , div
            [ classList
                [ ( "habit-amount-complete", True )
                , ( "editing", Maybe.isJust <| editingHabitAmount )
                ]
            ]
            [ input
                [ placeholder <|
                    String.fromInt habitDatum
                        ++ " "
                        ++ (if habitDatum == 1 then
                                habitRecord.unitNameSingular

                            else
                                habitRecord.unitNamePlural
                           )
                , onInput <| OnHabitAmountInput habitRecord.id
                , Util.onKeydownStopPropagation
                    (\key ->
                        if key == Keyboard.Enter then
                            Just <| SetHabitData selectedYmd habitRecord.id editingHabitAmount

                        else if key == Keyboard.KeyA then
                            Just OpenSetHabitDataShortcutHabitSelectionScreen

                        else if key == Keyboard.KeyN then
                            Just OpenAddNoteHabitSelectionDialogScreen

                        else if key == Keyboard.KeyC then
                            Just OnChooseCustomDateClick

                        else
                            Just NoOp
                    )
                , value <| Maybe.withDefault "" (Maybe.map String.fromInt editingHabitAmount)
                ]
                []
            , i
                [ classList [ ( "material-icons", True ) ]
                , onClick <| SetHabitData selectedYmd habitRecord.id editingHabitAmount
                ]
                [ text "check_box" ]
            ]
        ]


renderDialogBackgroundScreen : Maybe DialogScreen.DialogScreen -> Html Msg
renderDialogBackgroundScreen activeDialogScreen =
    let
        showBackgroundScreen : Bool
        showBackgroundScreen =
            Maybe.isJust activeDialogScreen
    in
    div
        [ classList
            [ ( "dialog-background-screen", True )
            , ( "display-none", not showBackgroundScreen )
            ]
        , onClick OnExitDialogScreen
        ]
        []


renderChooseDateDialog : Maybe DialogScreen.DialogScreen -> Maybe YmdDate.YmdDate -> Maybe YmdDate.YmdDate -> Html Msg
renderChooseDateDialog activeDialogScreen maybeChosenYmd maybeActualYmd =
    let
        showDialog : Bool
        showDialog =
            activeDialogScreen == Just DialogScreen.ChooseDateDialogScreen
    in
    case ( maybeChosenYmd, maybeActualYmd ) of
        ( Just chosenYmd, Just actualYmd ) ->
            let
                numDaysInMonth =
                    YmdDate.numDaysInMonth chosenYmd

                numCalendarRows =
                    ceiling <| toFloat numDaysInMonth / 7

                weekdayLetters : List String
                weekdayLetters =
                    List.map
                        (\ymd -> ymd |> YmdDate.prettyPrintWeekday |> String.left 1)
                        (List.map (\day -> { chosenYmd | day = day }) (List.range 1 7))

                renderWeekdayLetter : String -> Html Msg
                renderWeekdayLetter weekdayLetter =
                    div
                        [ class "choose-date-dialog-form-calendar-weekday-box" ]
                        [ text weekdayLetter ]

                calendarRows : List (List Int)
                calendarRows =
                    List.map
                        (\rowIndex -> List.range (rowIndex * 7 + 1) (rowIndex * 7 + 7))
                        (List.range 0 (numCalendarRows - 1))

                renderCalendarDayBox : Int -> Html Msg
                renderCalendarDayBox day =
                    let
                        representedYmd =
                            { chosenYmd | day = day }
                    in
                    div
                        [ classList
                            [ ( "choose-date-dialog-form-calendar-day-box", True )
                            , ( "choose-date-dialog-form-calendar-day-box-today", representedYmd == actualYmd )
                            , ( "choose-date-dialog-form-calendar-day-box-chosen", representedYmd == chosenYmd )
                            , ( "choose-date-dialog-form-calendar-day-box-empty-placeholder", day > numDaysInMonth )
                            ]
                        , onClick <| SetChooseDateDialogChosenYmd representedYmd
                        ]
                        [ text <| String.fromInt day ]

                renderCalendarRow : List Int -> Html Msg
                renderCalendarRow days =
                    div
                        [ class "choose-date-dialog-form-calendar-row" ]
                        (List.map renderCalendarDayBox days)

                yesterday =
                    YmdDate.addDays -1 actualYmd

                tomorrow =
                    YmdDate.addDays 1 actualYmd
            in
            div
                [ classList
                    [ ( "choose-date-dialog", True )
                    , ( "display-none", not showDialog )
                    ]
                ]
                [ div
                    [ class "choose-date-dialog-form"
                    , id "choose-date-dialog-form-id"
                    , tabindex 0
                    , Util.onKeydownStopPropagation
                        (\key ->
                            if key == Keyboard.KeyT then
                                Just <| SetChooseDateDialogChosenYmd actualYmd

                            else if key == Keyboard.ArrowDown then
                                Just <| SetChooseDateDialogChosenYmd (YmdDate.addDays 7 chosenYmd)

                            else if key == Keyboard.ArrowUp then
                                Just <| SetChooseDateDialogChosenYmd (YmdDate.addDays -7 chosenYmd)

                            else if key == Keyboard.ArrowLeft then
                                Just <| SetChooseDateDialogChosenYmd (YmdDate.addDays -1 chosenYmd)

                            else if key == Keyboard.ArrowRight then
                                Just <| SetChooseDateDialogChosenYmd (YmdDate.addDays 1 chosenYmd)

                            else if key == Keyboard.Enter then
                                Just <| OnChooseDateDialogSubmitClick chosenYmd

                            else if key == Keyboard.Escape then
                                Just OnExitDialogScreen

                            else
                                Just NoOp
                        )
                    ]
                    [ div
                        [ class "choose-date-dialog-form-chosen-ymd-text" ]
                        [ text <| YmdDate.prettyPrintWithWeekday chosenYmd ]
                    , div
                        [ class "choose-date-dialog-form-change-date-buttons" ]
                        [ button
                            [ classList
                                [ ( "choose-date-dialog-form-change-date-button", True )
                                , ( "selected", chosenYmd == yesterday )
                                ]
                            , onClick <| SetChooseDateDialogChosenYmd yesterday
                            ]
                            [ text "Yesterday" ]
                        , button
                            [ classList
                                [ ( "choose-date-dialog-form-change-date-button", True )
                                , ( "selected", chosenYmd == actualYmd )
                                ]
                            , onClick <| SetChooseDateDialogChosenYmd actualYmd
                            ]
                            [ text "Today" ]
                        , button
                            [ classList
                                [ ( "choose-date-dialog-form-change-date-button", True )
                                , ( "selected", chosenYmd == tomorrow )
                                ]
                            , onClick <| SetChooseDateDialogChosenYmd tomorrow
                            ]
                            [ text "Tomorrow" ]
                        ]
                    , div
                        [ class "choose-date-dialog-form-calendar" ]
                        [ div
                            [ class "choose-date-dialog-form-calendar-month-or-day-or-year" ]
                            [ span
                                [ class "choose-date-dialog-form-calendar-month-or-day-or-year-left-arrow"
                                , onClick <| OnChooseDateDialogPreviousMonthClick chosenYmd
                                ]
                                []
                            , span [] [ text <| YmdDate.prettyPrintMonth chosenYmd.month ]
                            , span
                                [ class "choose-date-dialog-form-calendar-month-or-day-or-year-right-arrow"
                                , onClick <| OnChooseDateDialogNextMonthClick chosenYmd
                                ]
                                []
                            ]
                        , div
                            [ class "choose-date-dialog-form-calendar-month-or-day-or-year" ]
                            [ span
                                [ class "choose-date-dialog-form-calendar-month-or-day-or-year-left-arrow"
                                , onClick <| OnChooseDateDialogPreviousDayClick chosenYmd
                                ]
                                []
                            , span [] [ text <| YmdDate.prettyPrintDay chosenYmd.day ]
                            , span
                                [ class "choose-date-dialog-form-calendar-month-or-day-or-year-right-arrow"
                                , onClick <| OnChooseDateDialogNextDayClick chosenYmd
                                ]
                                []
                            ]
                        , div
                            [ class "choose-date-dialog-form-calendar-month-or-day-or-year" ]
                            [ span
                                [ class "choose-date-dialog-form-calendar-month-or-day-or-year-left-arrow"
                                , onClick <| OnChooseDateDialogPreviousYearClick chosenYmd
                                ]
                                []
                            , span [] [ text <| String.fromInt chosenYmd.year ]
                            , span
                                [ class "choose-date-dialog-form-calendar-month-or-day-or-year-right-arrow"
                                , onClick <| OnChooseDateDialogNextYearClick chosenYmd
                                ]
                                []
                            ]
                        , div
                            [ class "choose-date-dialog-form-calendar-weekdays" ]
                            (List.map renderWeekdayLetter weekdayLetters)
                        , div
                            [ class "choose-date-dialog-form-calendar-rows" ]
                            (List.map renderCalendarRow calendarRows)
                        ]
                    , div
                        [ class "choose-date-dialog-form-submit-buttons" ]
                        [ button
                            [ class "choose-date-dialog-form-submit-buttons-submit"
                            , onClick <| OnChooseDateDialogSubmitClick chosenYmd
                            ]
                            [ text "Submit" ]
                        , button
                            [ class "choose-date-dialog-form-submit-buttons-cancel"
                            , onClick OnExitDialogScreen
                            ]
                            [ text "Cancel" ]
                        ]
                    ]
                ]

        _ ->
            div
                [ classList
                    [ ( "choose-date-dialog", True )
                    , ( "display-none", not showDialog )
                    ]
                ]
                [ div
                    [ class "choose-date-dialog-form"
                    , id "choose-date-dialog-form-id"
                    , tabindex 0
                    ]
                    [ text "Loading..." ]
                ]


renderHabitSelectionScreen :
    Bool
    -> String
    -> String
    -> (String -> Msg)
    -> String
    -> Array.Array Habit.Habit
    -> Msg
    -> Msg
    -> (Habit.Habit -> Msg)
    -> Int
    -> Html Msg
renderHabitSelectionScreen showScreen headerText inputId onInputMsg filterText filteredHabits onArrowUp onArrowDown onChooseHabit selectedHabitIndex =
    let
        selectedHabit =
            Array.get selectedHabitIndex filteredHabits

        readyToEnterHabit =
            Maybe.isJust selectedHabit

        renderHabitOption habit =
            div
                [ classList
                    [ ( "habit-selection-habits-list-option", True )
                    , ( "selected-habit"
                      , case selectedHabit of
                            Just h ->
                                h == habit

                            _ ->
                                False
                      )
                    ]
                ]
                [ text <| .name <| Habit.getCommonFields habit ]
    in
    div
        [ classList
            [ ( "habit-selection-screen", True )
            , ( "display-none", not showScreen )
            ]
        ]
        [ span
            [ class "habit-selection-screen-header" ]
            [ text headerText ]
        , input
            [ id inputId
            , class "habit-selection-filter-text-input"
            , placeholder "Enter a habit's name..."
            , onInput onInputMsg
            , value filterText
            , Util.onKeydownStopPropagation
                (\key ->
                    if key == Keyboard.ArrowDown then
                        Just onArrowDown

                    else if key == Keyboard.ArrowUp then
                        Just onArrowUp

                    else if key == Keyboard.Enter && readyToEnterHabit then
                        case selectedHabit of
                            Just h ->
                                Just <| onChooseHabit h

                            _ ->
                                Just NoOp

                    else if key == Keyboard.Escape then
                        Just OnExitDialogScreen

                    else
                        Just NoOp
                )
            ]
            []
        , div
            [ classList
                [ ( "habit-selection-habits-list", True )
                , ( "display-none", Array.isEmpty filteredHabits )
                ]
            ]
            (Array.map renderHabitOption filteredHabits |> Array.toList)
        ]


renderSetHabitDataShortcutHabitSelectionScreen :
    Maybe DialogScreen.DialogScreen
    -> String
    -> Array.Array Habit.Habit
    -> Int
    -> Html Msg
renderSetHabitDataShortcutHabitSelectionScreen activeDialogScreen habitSelectionFilterText filteredHabits selectedHabitIndex =
    let
        showScreen =
            activeDialogScreen == Just DialogScreen.SetHabitDataShortcutHabitSelectionScreen
    in
    renderHabitSelectionScreen
        showScreen
        "Set Habit Data"
        "set-habit-data-shortcut-habit-selection-filter-text-input"
        OnSetHabitDataShortcutHabitSelectionFilterTextInput
        habitSelectionFilterText
        filteredHabits
        OnSetHabitDataShortcutSelectPreviousHabit
        OnSetHabitDataShortcutSelectNextHabit
        OpenSetHabitDataShortcutAmountScreen
        selectedHabitIndex


renderSetHabitDataShortcutAmountScreen :
    Maybe DialogScreen.DialogScreen
    -> RemoteData.RemoteData ApiError.ApiError (List HabitData.HabitData)
    -> Maybe Habit.Habit
    -> Maybe Int
    -> Maybe YmdDate.YmdDate
    -> Html Msg
renderSetHabitDataShortcutAmountScreen activeDialogScreen rdHabitData maybeHabit maybeInputtedAmount maybeSelectedYmd =
    div
        [ classList
            [ ( "set-habit-data-shortcut-amount-screen", True )
            , ( "display-none", activeDialogScreen /= Just DialogScreen.SetHabitDataShortcutAmountScreen )
            ]
        ]
        (case ( maybeHabit, maybeSelectedYmd, rdHabitData ) of
            ( Just habit, Just selectedYmd, RemoteData.Success habitData ) ->
                let
                    habitRecord =
                        Habit.getCommonFields habit

                    habitDatum =
                        List.filter (\{ habitId, date } -> habitId == habitRecord.id && date == selectedYmd) habitData
                            |> List.head
                            |> (\maybeHabitDatum ->
                                    case maybeHabitDatum of
                                        Nothing ->
                                            0

                                        Just { amount } ->
                                            amount
                               )

                    readyToEnterAmount =
                        Maybe.isJust maybeInputtedAmount
                in
                [ span
                    [ class "set-habit-data-shortcut-amount-screen-selected-habit-name" ]
                    [ text <| .name habitRecord ]
                , input
                    [ id "set-habit-data-shortcut-amount-screen-input"
                    , class "set-habit-data-shortcut-amount-screen-input"
                    , placeholder <|
                        String.fromInt habitDatum
                            ++ " "
                            ++ (if habitDatum == 1 then
                                    habitRecord.unitNameSingular

                                else
                                    habitRecord.unitNamePlural
                               )
                    , onInput OnSetHabitDataShortcutAmountScreenInput
                    , value <| Maybe.withDefault "" (Maybe.map String.fromInt maybeInputtedAmount)
                    , Util.onKeydownStopPropagation
                        (\key ->
                            if key == Keyboard.Escape then
                                Just OpenSetHabitDataShortcutHabitSelectionScreen

                            else if key == Keyboard.Enter then
                                case maybeInputtedAmount of
                                    Just amount ->
                                        Just <| OnSetHabitDataShortcutAmountScreenSubmit selectedYmd habitRecord.id amount

                                    Nothing ->
                                        Just NoOp

                            else
                                Just NoOp
                        )
                    ]
                    []
                ]

            _ ->
                []
        )


renderEditGoalDialog : Maybe DialogScreen.DialogScreen -> Maybe Habit.Habit -> Habit.EditGoalInputData -> Maybe YmdDate.YmdDate -> Html Msg
renderEditGoalDialog activeDialogScreen habit editGoal maybeActualYmd =
    case maybeActualYmd of
        Just actualYmd ->
            div
                [ classList
                    [ ( "edit-goal-dialog", True )
                    , ( "display-none", activeDialogScreen /= Just DialogScreen.EditGoalScreen )
                    ]
                ]
                (case habit of
                    Just h ->
                        let
                            habitRecord =
                                Habit.getCommonFields h

                            isGoodHabit =
                                case h of
                                    Habit.GoodHabit _ ->
                                        True

                                    _ ->
                                        False

                            currentGoal : Maybe Habit.FrequencyChangeRecord
                            currentGoal =
                                case h of
                                    Habit.GoodHabit gh ->
                                        List.head <| List.reverse gh.targetFrequencies

                                    Habit.BadHabit bh ->
                                        List.head <| List.reverse bh.thresholdFrequencies

                            ( currentGoalTag, currentGoalDesc ) =
                                case currentGoal of
                                    Just fcr ->
                                        ( case fcr.newFrequency of
                                            Habit.EveryXDayFrequency f ->
                                                "Y Per X Days"

                                            Habit.TotalWeekFrequency f ->
                                                "X Per Week"

                                            Habit.SpecificDayOfWeekFrequency f ->
                                                "Specific Days of Week"
                                        , Habit.prettyPrintFrequency fcr.newFrequency habitRecord.unitNameSingular habitRecord.unitNamePlural
                                        )

                                    Nothing ->
                                        ( "N/A", "N/A" )

                            newGoalDesc : String
                            newGoalDesc =
                                case editGoal.frequencyKind of
                                    Habit.TotalWeekFrequencyKind ->
                                        Maybe.withDefault "_" (Maybe.map String.fromInt editGoal.timesPerWeek)
                                            ++ " "
                                            ++ (if Maybe.withDefault 0 editGoal.timesPerWeek == 1 then
                                                    habitRecord.unitNameSingular

                                                else
                                                    habitRecord.unitNamePlural
                                               )
                                            ++ " per week"

                                    Habit.SpecificDayOfWeekFrequencyKind ->
                                        "Mo "
                                            ++ Maybe.withDefault "_" (Maybe.map String.fromInt editGoal.mondayTimes)
                                            ++ " Tu "
                                            ++ Maybe.withDefault "_" (Maybe.map String.fromInt editGoal.tuesdayTimes)
                                            ++ " We "
                                            ++ Maybe.withDefault "_" (Maybe.map String.fromInt editGoal.wednesdayTimes)
                                            ++ " Th "
                                            ++ Maybe.withDefault "_" (Maybe.map String.fromInt editGoal.thursdayTimes)
                                            ++ " Fr "
                                            ++ Maybe.withDefault "_" (Maybe.map String.fromInt editGoal.fridayTimes)
                                            ++ " Sa "
                                            ++ Maybe.withDefault "_" (Maybe.map String.fromInt editGoal.saturdayTimes)
                                            ++ " Su "
                                            ++ Maybe.withDefault "_" (Maybe.map String.fromInt editGoal.sundayTimes)

                                    Habit.EveryXDayFrequencyKind ->
                                        Maybe.withDefault "_" (Maybe.map String.fromInt editGoal.times)
                                            ++ " "
                                            ++ (if Maybe.withDefault 0 editGoal.times == 1 then
                                                    habitRecord.unitNameSingular

                                                else
                                                    habitRecord.unitNamePlural
                                               )
                                            ++ " per "
                                            ++ (if Maybe.withDefault 0 editGoal.days == 1 then
                                                    "day"

                                                else
                                                    Maybe.withDefault "_" (Maybe.map String.fromInt editGoal.days) ++ " days"
                                               )

                            oldFrequencies : List Habit.FrequencyChangeRecord
                            oldFrequencies =
                                case h of
                                    Habit.GoodHabit gh ->
                                        gh.targetFrequencies

                                    Habit.BadHabit bh ->
                                        bh.thresholdFrequencies

                            newGoal =
                                Habit.extractNewGoal editGoal

                            isWeeklyNewGoal =
                                editGoal.frequencyKind == Habit.TotalWeekFrequencyKind

                            newStartDate : YmdDate.YmdDate
                            newStartDate =
                                if isWeeklyNewGoal then
                                    YmdDate.getFirstMondayAfterDate actualYmd

                                else
                                    actualYmd

                            newFrequencies =
                                case newGoal of
                                    Just newFrequency ->
                                        case List.reverse oldFrequencies of
                                            currFcr :: rest ->
                                                if List.member (YmdDate.compareYmds currFcr.startDate actualYmd) [ EQ, GT ] then
                                                    -- The current goal started today or later, we should overwrite it.
                                                    -- (At this point there should only possibly be one goal, the current one,
                                                    -- that started today or later.)
                                                    case rest of
                                                        secondLastFcr :: restTwo ->
                                                            Just <|
                                                                List.reverse <|
                                                                    { startDate = newStartDate
                                                                    , endDate = Nothing
                                                                    , newFrequency = newFrequency
                                                                    }
                                                                        :: { secondLastFcr | endDate = Just <| YmdDate.addDays -1 newStartDate }
                                                                        :: restTwo

                                                        [] ->
                                                            -- `currFcr` was the only goal and we are replacing it
                                                            Just [ { startDate = newStartDate, endDate = Nothing, newFrequency = newFrequency } ]

                                                else
                                                    Just <|
                                                        List.reverse <|
                                                            { startDate = newStartDate, endDate = Nothing, newFrequency = newFrequency }
                                                                :: { currFcr | endDate = Just <| YmdDate.addDays -1 newStartDate }
                                                                :: rest

                                            [] ->
                                                -- there are no existing goals (this shouldn't happen though)
                                                Just [ { startDate = newStartDate, endDate = Nothing, newFrequency = newFrequency } ]

                                    Nothing ->
                                        -- User has not fully filled out form, we don't need to compute `newFrequencies` yet
                                        Nothing

                            confirmationMessage : String
                            confirmationMessage =
                                case newGoal of
                                    Just newFrequency ->
                                        case currentGoal of
                                            Just fcr ->
                                                "The previous goal for "
                                                    ++ habitRecord.name
                                                    ++ " was "
                                                    ++ Habit.prettyPrintFrequency fcr.newFrequency habitRecord.unitNameSingular habitRecord.unitNamePlural
                                                    ++ ". The new goal "
                                                    ++ Habit.prettyPrintFrequency newFrequency habitRecord.unitNameSingular habitRecord.unitNamePlural
                                                    ++ " will officially start "
                                                    ++ (if newStartDate == actualYmd then
                                                            "today (" ++ YmdDate.prettyPrintWithWeekday newStartDate ++ ")."

                                                        else
                                                            "on " ++ YmdDate.prettyPrintWithWeekday newStartDate ++ "."
                                                       )

                                            Nothing ->
                                                "The new goal "
                                                    ++ newGoalDesc
                                                    ++ " will officially start on "
                                                    ++ YmdDate.prettyPrintWithWeekday newStartDate
                                                    ++ "."

                                    Nothing ->
                                        ""
                        in
                        [ div
                            [ class "edit-goal-dialog-form" ]
                            [ div
                                [ class "edit-goal-dialog-form-header" ]
                                [ text habitRecord.name ]
                            , div [ class "edit-goal-dialog-form-line-break" ] []
                            , div
                                [ class "edit-goal-dialog-form-current-goal-text" ]
                                [ text "Current Goal" ]
                            , div
                                [ class "edit-goal-dialog-form-current-goal-tag" ]
                                [ button [] [ text currentGoalTag ] ]
                            , div
                                [ class "edit-goal-dialog-form-current-goal-description" ]
                                [ text currentGoalDesc ]
                            , div
                                [ class "edit-goal-dialog-form-new-goal-line-break" ]
                                []
                            , div
                                [ class "edit-goal-dialog-form-new-goal-header" ]
                                [ text "New Goal" ]
                            , div
                                [ class "edit-goal-dialog-form-new-goal-frequency-tags" ]
                                [ button
                                    [ classList [ ( "selected", editGoal.frequencyKind == Habit.TotalWeekFrequencyKind ) ]
                                    , onClick <| OnEditGoalSelectFrequencyKind Habit.TotalWeekFrequencyKind
                                    ]
                                    [ text "X Per Week" ]
                                , button
                                    [ classList [ ( "selected", editGoal.frequencyKind == Habit.SpecificDayOfWeekFrequencyKind ) ]
                                    , onClick <| OnEditGoalSelectFrequencyKind Habit.SpecificDayOfWeekFrequencyKind
                                    ]
                                    [ text "Specific Days of Week" ]
                                , button
                                    [ classList [ ( "selected", editGoal.frequencyKind == Habit.EveryXDayFrequencyKind ) ]
                                    , onClick <| OnEditGoalSelectFrequencyKind Habit.EveryXDayFrequencyKind
                                    ]
                                    [ text "Y Per X Days" ]
                                ]
                            , div
                                [ class "edit-goal-dialog-form-new-goal-description" ]
                                [ text newGoalDesc ]
                            , div
                                [ class "edit-goal-dialog-form-new-goal-forms" ]
                                [ div
                                    [ classList
                                        [ ( "edit-goal-dialog-form-new-goal-total-week-frequency-form", True )
                                        , ( "display-none", editGoal.frequencyKind /= Habit.TotalWeekFrequencyKind )
                                        ]
                                    ]
                                    [ inputStopKeydownPropagation
                                        [ placeholder "X"
                                        , onInput OnEditGoalTimesPerWeekInput
                                        , value <| Maybe.withDefault "" (Maybe.map String.fromInt editGoal.timesPerWeek)
                                        ]
                                        []
                                    ]
                                , div
                                    [ classList
                                        [ ( "edit-goal-dialog-form-new-goal-specific-day-of-week-frequency-form", True )
                                        , ( "display-none", editGoal.frequencyKind /= Habit.SpecificDayOfWeekFrequencyKind )
                                        ]
                                    ]
                                    [ inputStopKeydownPropagation
                                        [ placeholder "Monday"
                                        , onInput OnEditGoalSpecificDayMondayInput
                                        , value <| Maybe.withDefault "" (Maybe.map String.fromInt editGoal.mondayTimes)
                                        ]
                                        []
                                    , inputStopKeydownPropagation
                                        [ placeholder "Tuesday"
                                        , onInput OnEditGoalSpecificDayTuesdayInput
                                        , value <| Maybe.withDefault "" (Maybe.map String.fromInt editGoal.tuesdayTimes)
                                        ]
                                        []
                                    , inputStopKeydownPropagation
                                        [ placeholder "Wednesday"
                                        , onInput OnEditGoalSpecificDayWednesdayInput
                                        , value <| Maybe.withDefault "" (Maybe.map String.fromInt editGoal.wednesdayTimes)
                                        ]
                                        []
                                    , inputStopKeydownPropagation
                                        [ placeholder "Thursday"
                                        , onInput OnEditGoalSpecificDayThursdayInput
                                        , value <| Maybe.withDefault "" (Maybe.map String.fromInt editGoal.thursdayTimes)
                                        ]
                                        []
                                    , inputStopKeydownPropagation
                                        [ placeholder "Friday"
                                        , onInput OnEditGoalSpecificDayFridayInput
                                        , value <| Maybe.withDefault "" (Maybe.map String.fromInt editGoal.fridayTimes)
                                        ]
                                        []
                                    , inputStopKeydownPropagation
                                        [ placeholder "Saturday"
                                        , onInput OnEditGoalSpecificDaySaturdayInput
                                        , value <| Maybe.withDefault "" (Maybe.map String.fromInt editGoal.saturdayTimes)
                                        ]
                                        []
                                    , inputStopKeydownPropagation
                                        [ placeholder "Sunday"
                                        , onInput OnEditGoalSpecificDaySundayInput
                                        , value <| Maybe.withDefault "" (Maybe.map String.fromInt editGoal.sundayTimes)
                                        ]
                                        []
                                    ]
                                , div
                                    [ classList
                                        [ ( "edit-goal-dialog-form-new-goal-every-x-days-frequency-form", True )
                                        , ( "display-none", editGoal.frequencyKind /= Habit.EveryXDayFrequencyKind )
                                        ]
                                    ]
                                    [ inputStopKeydownPropagation
                                        [ placeholder "Times"
                                        , onInput OnEditGoalTimesInput
                                        , value <| Maybe.withDefault "" (Maybe.map String.fromInt editGoal.times)
                                        ]
                                        []
                                    , inputStopKeydownPropagation
                                        [ placeholder "Days"
                                        , onInput OnEditGoalDaysInput
                                        , value <| Maybe.withDefault "" (Maybe.map String.fromInt editGoal.days)
                                        ]
                                        []
                                    ]
                                ]
                            , div
                                [ classList
                                    [ ( "edit-goal-dialog-form-confirmation-message-line-break", True )
                                    , ( "display-none", not <| Maybe.isJust newGoal )
                                    ]
                                ]
                                []
                            , div
                                [ classList
                                    [ ( "edit-goal-dialog-form-confirmation-message", True )
                                    , ( "display-none", not <| Maybe.isJust newGoal )
                                    ]
                                ]
                                [ text confirmationMessage ]
                            , div
                                [ classList
                                    [ ( "edit-goal-dialog-form-buttons", True )
                                    , ( "display-none", not <| Maybe.isJust newGoal )
                                    ]
                                ]
                                [ button
                                    [ class "edit-goal-dialog-form-buttons-submit"
                                    , onClick <|
                                        case newFrequencies of
                                            Just fcrs ->
                                                OnEditGoalSubmitClick
                                                    habitRecord.id
                                                    fcrs
                                                    (if isGoodHabit then
                                                        "good_habit"

                                                     else
                                                        "bad_habit"
                                                    )

                                            Nothing ->
                                                NoOp
                                    ]
                                    [ text "Submit" ]
                                , button
                                    [ class "edit-goal-dialog-form-buttons-cancel"
                                    , onClick CloseEditGoalDialog
                                    ]
                                    [ text "Cancel" ]
                                ]
                            ]
                        ]

                    Nothing ->
                        []
                )

        Nothing ->
            div [] []


renderErrorMessage : Maybe String -> Maybe DialogScreen.DialogScreen -> Html Msg
renderErrorMessage errorMessage activeDialogScreen =
    div
        [ classList
            [ ( "error-message", True )
            , ( "display-none", activeDialogScreen /= Just DialogScreen.ErrorMessageScreen )
            ]
        ]
        [ div
            [ class "error-message-text" ]
            [ text <|
                Maybe.withDefault
                    "No errors"
                    (Maybe.map (\em -> em ++ ". You may want to refresh the page.") errorMessage)
            ]
        ]


renderAddNoteHabitSelectionScreen :
    Maybe DialogScreen.DialogScreen
    -> String
    -> Array.Array Habit.Habit
    -> Int
    -> Html Msg
renderAddNoteHabitSelectionScreen activeDialogScreen habitSelectionFilterText filteredHabits selectedHabitIndex =
    let
        showScreen =
            activeDialogScreen == Just DialogScreen.AddNoteHabitSelectionScreen
    in
    renderHabitSelectionScreen
        showScreen
        "Add Note"
        "add-note-habit-selection-filter-text-input"
        OnAddNoteHabitSelectionFilterTextInput
        habitSelectionFilterText
        filteredHabits
        OnAddNoteHabitSelectionScreenSelectPreviousHabit
        OnAddNoteHabitSelectionScreenSelectNextHabit
        OpenAddNoteDialog
        selectedHabitIndex


renderAddNoteDialog :
    Maybe DialogScreen.DialogScreen
    -> Maybe Habit.Habit
    -> String
    -> Maybe YmdDate.YmdDate
    -> RemoteData.RemoteData ApiError.ApiError (List HabitDayNote.HabitDayNote)
    -> Html Msg
renderAddNoteDialog activeDialogScreen addNoteDialogHabit addNoteDialogInput maybeSelectedYmd rdAllHabitDayNotes =
    div
        [ classList
            [ ( "add-note-dialog", True )
            , ( "display-none", activeDialogScreen /= Just DialogScreen.AddNoteScreen )
            ]
        ]
        (case ( addNoteDialogHabit, maybeSelectedYmd, rdAllHabitDayNotes ) of
            ( Just habit, Just selectedYmd, RemoteData.Success allHabitDayNotes ) ->
                let
                    habitRecord =
                        Habit.getCommonFields habit

                    existingHabitDayNoteText : Maybe String
                    existingHabitDayNoteText =
                        List.filter (\{ habitId, date } -> habitId == habitRecord.id && date == selectedYmd) allHabitDayNotes
                            |> List.head
                            |> Maybe.map .note
                in
                [ div
                    [ class "add-note-dialog-form" ]
                    [ div [ class "add-note-dialog-header-habit-name" ] [ text habitRecord.name ]
                    , div [ class "add-note-dialog-header-date" ] [ text <| YmdDate.prettyPrintWithWeekday selectedYmd ]
                    , div
                        [ classList
                            [ ( "add-note-dialog-header-note-added", True )
                            , ( "display-none", existingHabitDayNoteText /= Just addNoteDialogInput )
                            ]
                        ]
                        [ i [ class "material-icons" ] []
                        , text "Note Added"
                        ]
                    , div [ class "add-note-dialog-header-line-break" ] []
                    , textarea
                        [ class "add-note-dialog-input"
                        , placeholder <| Maybe.withDefault "Add a note for today..." existingHabitDayNoteText
                        , onInput OnAddNoteDialogInput
                        , value addNoteDialogInput
                        , id "add-note-dialog-input-id"
                        , Util.onKeydownStopPropagation
                            (\key ->
                                if key == Keyboard.Escape then
                                    Just OnExitDialogScreen

                                else
                                    Just <| OnAddNoteKeydown key selectedYmd habitRecord.id
                            )
                        , Util.onKeyupStopPropagation
                            (\key -> Just <| OnAddNoteKeyup key)
                        ]
                        []
                    , div
                        [ classList
                            [ ( "add-note-dialog-form-buttons", True )
                            , ( "display-none", addNoteDialogInput == "" )
                            ]
                        ]
                        [ button
                            [ class "add-note-dialog-form-buttons-submit"
                            , onClick <|
                                if addNoteDialogInput == "" then
                                    NoOp

                                else
                                    OnAddNoteSubmitClick selectedYmd habitRecord.id addNoteDialogInput
                            ]
                            [ text "Submit" ]
                        , button
                            [ class "add-note-dialog-form-buttons-cancel"
                            , onClick OnExitDialogScreen
                            ]
                            [ text "Cancel" ]
                        ]
                    ]
                ]

            _ ->
                []
        )


renderSuspendOrResumeHabitSelectionScreen :
    Maybe DialogScreen.DialogScreen
    -> String
    -> Array.Array Habit.Habit
    -> Int
    -> Html Msg
renderSuspendOrResumeHabitSelectionScreen activeDialogScreen habitSelectionFilterText filteredHabits selectedHabitIndex =
    let
        showScreen =
            activeDialogScreen == Just DialogScreen.SuspendOrResumeHabitSelectionScreen
    in
    renderHabitSelectionScreen
        showScreen
        "Suspend Or Resume Habit"
        "suspend-or-resume-habit-selection-filter-text-input"
        OnSuspendOrResumeHabitSelectionFilterTextInput
        habitSelectionFilterText
        filteredHabits
        OnSuspendOrResumeHabitSelectionSelectPreviousHabit
        OnSuspendOrResumeHabitSelectionSelectNextHabit
        OpenSuspendOrResumeConfirmationScreen
        selectedHabitIndex
