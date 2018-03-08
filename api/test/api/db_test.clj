(ns api.db-test
  (:require [clojure.test :refer :all]
            [clojure.data :refer [diff]]
            [api.db :refer :all]
            [monger.core :as mg]
            [monger.db :as mdb]
            [clj-time.core :as t]))

; Useful variables
(def test_conn (mg/connect))
(def test_db (mg/get-db test_conn "test_db"))
(def default_habit {:name "test habit" :description "test description" :unit_name_singular "test unit"
                    :unit_name_plural "test units" :time_of_day :ANYTIME})
(def today (t/today-at 0 0))

(defn add-habit-to-test-db
  "Add a habit to the test database"
  [habit]
  (add-habit {:db test_db :habit habit}))

(defn compare_clojure_habit_with_db_habit
  "Returns true iff all fields of `clojure_habit` have the same value in `db_habit`.
  Checks Keyword values in `clojure_habit` against the Keyword-ed version of the value in `db_habit`
  since Keywords are converted to Strings by Monger.
  Note that this function doesn't care if `db_habit` has a field that `clojure_habit` doesn't have."
  [clojure_habit db_habit]
  (every? (fn [key]
           (let [clj_val (key clojure_habit)
                 db_val (key db_habit)]
             (if (= (type clj_val) clojure.lang.Keyword)
               (= clj_val (keyword db_val))
               (= clj_val db_val))))
          (keys clojure_habit)))

(deftest add-habit-test
  (testing "No habits"
    (is (= 0 (count (get-habits {:db test_db})))))
  (let [habit_1 (assoc default_habit
                       :type_name "good_habit"
                       :target_frequency {:type_name "total_week_frequency"
                                          :week 6})
        _ (add-habit-to-test-db habit_1)
        all_habits (get-habits {:db test_db})]
    (testing "One habit"
      (is (= 1 (count all_habits)) "There should be one habit in the db")
      (is (some #(compare_clojure_habit_with_db_habit habit_1 %) all_habits) "Habit 1 not added properly")
      (is (every? #(= false (:suspended %)) all_habits) ":suspended field not set to false")
      (is (every? #(not (nil? (:_id %))) all_habits) ":_id field not set"))
    (let [habit_2 (assoc default_habit
                         :type_name "bad_habit"
                         :threshold_frequency {:type_name "every_x_days_frequency"
                                               :days 4
                                               :times 3})
          _ (add-habit-to-test-db habit_2)
          all_habits (get-habits {:db test_db})]
      (testing "Two habits"
        (is (= 2 (count all_habits)) "There should be two habits in the db")
        (is (some #(compare_clojure_habit_with_db_habit habit_1 %) all_habits) "Habit 1 not added properly")
        (is (some #(compare_clojure_habit_with_db_habit habit_2 %) all_habits) "Habit 2 not added properly")
        (is (every? #(= false (:suspended %)) all_habits) ":suspended field not set to false")
        (is (every? #(not (nil? (:_id %))) all_habits) ":_id field not set")))))

(deftest get-frequency-stats-test
  (testing "No habits added yet"
    (is (= 0 (count (get-habits {:db test_db})))))
  (testing "Good habit, specific day of week frequency"
    (let [habit (assoc default_habit
                       :type_name "good_habit"
                       :target_frequency {:type_name "specific_day_of_week_frequency"
                                          :monday 2 :tuesday 2 :wednesday 2 :thursday 2
                                          :friday 2 :saturday 2 :sunday 2})
          final_habit (add-habit-to-test-db habit)
          habit_id (str (:_id final_habit))]
      (testing "with no habit data"
        (is (= 1 (count (get-habits {:db test_db}))) "There should only be one habit so far")
        (is (= [nil] (get-frequency-stats {:db test_db :habit_ids [habit_id]})))
        (is (= [nil] (get-frequency-stats {:db test_db})) "`habit_ids` should be an optional param"))
      (testing "with a successful habit record yesterday"
        (let [_ (set-habit-data {:db test_db :habit_id habit_id :amount 4
                                 :date-time (t/minus today (t/days 1))})
              stats (get-frequency-stats {:db test_db :habit_ids [habit_id]})]
          (is (= stats [{:habit_id habit_id
                         :total_fragments 1 :successful_fragments 1
                         :total_done 4 :fragment_streak 1}])))
        (testing "and a failure habit record the day before"
          (let [_ (set-habit-data {:db test_db :habit_id habit_id :amount 1
                                   :date-time (t/minus today (t/days 2))})
                stats (get-frequency-stats {:db test_db :habit_ids [habit_id]})]
            (is (= stats [{:habit_id habit_id
                           :total_fragments 2 :successful_fragments 1
                           :total_done 5 :fragment_streak 1}])))))))
  (testing "Good habit, total week frequency"
    (let [habit (assoc default_habit
                       :type_name "good_habit"
                       :target_frequency {:type_name "total_week_frequency"
                                          :week 5})
          final_habit (add-habit-to-test-db habit)
          habit_id (str (:_id final_habit))]
      (testing "with last week as a failure"
        (let [_ (set-habit-data {:db test_db :habit_id habit_id :amount 3
                                 ; 7 days ago was in the previous week, which has now ended
                                 :date-time (t/minus today (t/days 7))})
              stats (get-frequency-stats {:db test_db :habit_ids [habit_id]})]
          (is (= stats [{:habit_id habit_id
                         ; the only fragment that has ended (starting from the first habit data) was last week
                         :total_fragments 1 :successful_fragments 0
                         :total_done 3 :fragment_streak 0}])))
        (testing "and the week before as a success"
          (let [_ (set-habit-data {:db test_db :habit_id habit_id :amount 5
                                   :date-time (t/minus today (t/days 14))})
                stats (get-frequency-stats {:db test_db :habit_ids [habit_id]})]
            (is (= stats [{:habit_id habit_id
                           :total_fragments 2 :successful_fragments 1
                           :total_done 8 :fragment_streak 1}]))))))))

(defn drop-test-db-fixture
  "Drop test database before and after each test"
  [f]
  (mdb/drop-db test_db)
  (f)
  (mdb/drop-db test_db))

(use-fixtures :each drop-test-db-fixture)