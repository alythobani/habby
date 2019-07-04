module Models.Graph exposing
    ( GraphData
    , NumberOfDaysToShow(..)
    , Point
    , amountAxisConfig
    , amountIntToTickConfig
    , customConfig
    , dateAxisConfig
    , dateIntToTickConfig
    , getAllGraphData
    , getAllGraphIntervalSeries
    )

import Array
import Color
import DefaultServices.Util as Util
import LineChart
import LineChart.Area as Area
import LineChart.Axis as Axis
import LineChart.Axis.Intersection as Intersection
import LineChart.Axis.Line as AxisLine
import LineChart.Axis.Range as Range
import LineChart.Axis.Tick as Tick
import LineChart.Axis.Ticks as Ticks
import LineChart.Axis.Title as Title
import LineChart.Colors as Colors
import LineChart.Container as Container
import LineChart.Dots as Dots
import LineChart.Events as Events
import LineChart.Grid as Grid
import LineChart.Interpolation as Interpolation
import LineChart.Junk as Junk
import LineChart.Legends as Legends
import LineChart.Line as Line
import Models.HabitGoalIntervalList exposing (HabitGoalInterval)
import Models.YmdDate as YmdDate


type alias Point =
    { dateFloat : Float
    , amountFloat : Float
    , goalIntervalIndex : Int
    }


type alias GraphData =
    List Point


getAllGraphData : List HabitGoalInterval -> GraphData
getAllGraphData goalIntervals =
    let
        goalIntervalsArray =
            Array.fromList goalIntervals
    in
    goalIntervals
        |> List.indexedMap
            (\goalIntervalIndex goalInterval ->
                YmdDate.numDaysSpanned goalInterval.startDate goalInterval.endDate
                    |> List.range 0
                    |> List.map
                        (always
                            { amountFloat = toFloat goalInterval.totalDone
                            , goalIntervalIndex = goalIntervalIndex
                            }
                        )
            )
        |> List.concat
        |> List.indexedMap
            (\pointIndex point ->
                { dateFloat = toFloat pointIndex
                , amountFloat = point.amountFloat
                , goalIntervalIndex = point.goalIntervalIndex
                }
            )


getAllGraphIntervalSeries : List HabitGoalInterval -> List (LineChart.Series Point)
getAllGraphIntervalSeries allGoalIntervals =
    let
        allPoints =
            getAllGraphData allGoalIntervals
    in
    List.indexedMap
        (\goalIntervalIndex goalInterval ->
            let
                lineColor : Color.Color
                lineColor =
                    if goalInterval.suspended || not goalInterval.valid then
                        Color.lightGray

                    else if goalInterval.successful then
                        Color.green

                    else
                        Color.red

                goalIntervalPoints =
                    List.filter (\point -> point.goalIntervalIndex == goalIntervalIndex) allPoints

                maybePreviousPointWithIndex =
                    Util.lastInstanceInArray (Array.fromList allPoints) (\point -> point.goalIntervalIndex == goalIntervalIndex - 1)

                goalIntervalPointsWithConnectorPoint =
                    case maybePreviousPointWithIndex of
                        Just ( previousPointIndex, previousPoint ) ->
                            previousPoint :: goalIntervalPoints

                        Nothing ->
                            goalIntervalPoints
            in
            LineChart.line
                lineColor
                Dots.none
                ("Habit Data " ++ String.fromInt goalIntervalIndex)
                goalIntervalPointsWithConnectorPoint
        )
        allGoalIntervals


type NumberOfDaysToShow
    = AllTime
    | LastMonth
    | LastThreeMonths
    | LastYear



-- Line Chart Configuration


customConfig : List HabitGoalInterval -> LineChart.Config Point msg
customConfig goalIntervals =
    let
        maybeStartYmd =
            List.head goalIntervals |> Maybe.map .startDate
    in
    { x = dateAxisConfig maybeStartYmd
    , y = amountAxisConfig
    , container = Container.default "graph-container-id"
    , interpolation = Interpolation.linear
    , intersection = Intersection.at 0 0
    , legends = Legends.none
    , events = Events.default
    , junk = Junk.default
    , grid = Grid.default
    , area = Area.default
    , line = Line.default
    , dots = Dots.custom <| Dots.aura 1 1 0.5
    }


dateAxisConfig : Maybe YmdDate.YmdDate -> Axis.Config Point msg
dateAxisConfig maybeStartYmd =
    Axis.custom
        { title = Title.default ""
        , variable = Just << .dateFloat
        , pixels = 700
        , range = Range.padded 20 20
        , axisLine = AxisLine.none
        , ticks = Ticks.intCustom 3 (dateIntToTickConfig maybeStartYmd)
        }


dateIntToTickConfig : Maybe YmdDate.YmdDate -> Int -> Tick.Config msg
dateIntToTickConfig maybeStartYmd numDaysToAdd =
    let
        labelStr =
            case maybeStartYmd of
                Just startYmd ->
                    startYmd |> YmdDate.addDays numDaysToAdd |> YmdDate.prettyPrintShortForm

                Nothing ->
                    String.fromInt numDaysToAdd
    in
    Tick.custom
        { position = toFloat numDaysToAdd
        , color = Colors.transparent
        , width = 2
        , length = 2
        , grid = False
        , direction = Tick.negative
        , label = Just <| Junk.label Color.white labelStr
        }


amountAxisConfig : Axis.Config Point msg
amountAxisConfig =
    Axis.custom
        { title = Title.default ""
        , variable = Just << .amountFloat
        , pixels = 500
        , range = Range.padded 20 20
        , axisLine = AxisLine.full Color.white
        , ticks = Ticks.intCustom 7 amountIntToTickConfig
        }


amountIntToTickConfig : Int -> Tick.Config msg
amountIntToTickConfig amountInt =
    Tick.custom
        { position = toFloat amountInt
        , color = Colors.transparent
        , width = 2
        , length = 2
        , grid = False
        , direction = Tick.negative
        , label = Just <| Junk.label Color.white (String.fromInt amountInt)
        }
