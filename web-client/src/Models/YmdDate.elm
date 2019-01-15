module Models.YmdDate exposing (YmdDate, addDays, decodeYmdDate, fromDate, fromSimpleString, getFirstMondayAfterDate, prettyPrint, toDate, toSimpleString)

import Date
import Date.Extra as Date
import Date.Extra.Facts exposing (monthFromMonthNumber)
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, hardcoded, optional, required)


type alias YmdDate =
    { day : Int, month : Int, year : Int }


prettyPrint : YmdDate -> String
prettyPrint ymd =
    let
        prettyMonth { month } =
            case month of
                1 ->
                    "January"

                2 ->
                    "February"

                3 ->
                    "March"

                4 ->
                    "April"

                5 ->
                    "May"

                6 ->
                    "June"

                7 ->
                    "July"

                8 ->
                    "August"

                9 ->
                    "September"

                10 ->
                    "October"

                11 ->
                    "November"

                12 ->
                    "December"

                _ ->
                    "Invalid Month Number"

        prettyDay { day } =
            toString day
                ++ (if List.member day [ 1, 21, 31 ] then
                        "st"

                    else if List.member day [ 2, 22 ] then
                        "nd"

                    else if List.member day [ 3, 23 ] then
                        "rd"

                    else
                        "th"
                   )
    in
    prettyMonth ymd ++ " " ++ prettyDay ymd ++ ", " ++ toString ymd.year


{-| Add days to a date to get a new date that many days away, you can add negative days to go back in time.
-}
addDays : Int -> YmdDate -> YmdDate
addDays dayDelta ymd =
    toDate ymd
        |> Date.add Date.Day dayDelta
        |> fromDate


toDate : YmdDate -> Date.Date
toDate ymd =
    Date.fromCalendarDate ymd.year (monthFromMonthNumber ymd.month) ymd.day


fromDate : Date.Date -> YmdDate
fromDate date =
    { year = Date.year date, month = Date.monthNumber date, day = Date.day date }


getFirstMondayAfterDate : YmdDate -> YmdDate
getFirstMondayAfterDate ymd =
    let
        -- Days are numbered 1 (Monday) to 7 (Sunday)
        ymdDayOfWeekNumber =
            toDate ymd |> Date.weekdayNumber

        -- Monday: 0, Tuesday: 6, Wednesday: 5, ..., Sunday: 1
        numDaysToAdd =
            (8 - ymdDayOfWeekNumber) % 7
    in
    addDays numDaysToAdd ymd


{-| From format "dd/mm/yy" where it's not required that dd or mm be 2 characters.

@refer toSimpleString

-}
fromSimpleString : String -> Maybe YmdDate
fromSimpleString date =
    String.split "/" date
        |> (\dateComponents ->
                case dateComponents of
                    [ day, monthNumber, shortenedYear ] ->
                        case ( String.toInt day, String.toInt monthNumber, String.toInt <| "20" ++ shortenedYear ) of
                            ( Ok day, Ok monthNumber, Ok year ) ->
                                Date.fromCalendarDate year (monthFromMonthNumber monthNumber) day
                                    |> fromDate
                                    |> Just

                            _ ->
                                Nothing

                    _ ->
                        Nothing
           )


{-| To format "dd/mm/yy", where dd and mm can be 1-char, they are not zero-padded.

@refer fromSimpleString

-}
toSimpleString : YmdDate -> String
toSimpleString { year, month, day } =
    Basics.toString day ++ "/" ++ Basics.toString month ++ "/" ++ (String.dropLeft 2 <| Basics.toString year)


decodeYmdDate : Decode.Decoder YmdDate
decodeYmdDate =
    decode YmdDate
        |> required "day" Decode.int
        |> required "month" Decode.int
        |> required "year" Decode.int
