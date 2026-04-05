-- Решение задач по базе данных "Автомобильные гонки"

-- Задача 3.
-- Определить классы автомобилей, которые имеют наименьшую среднюю позицию в гонках,
-- и вывести информацию о каждом автомобиле из этих классов, включая его имя,
-- среднюю позицию, количество гонок, в которых он участвовал, страну производства класса автомобиля,
-- а также общее количество гонок, в которых участвовали автомобили этих классов.
-- Если несколько классов имеют одинаковую среднюю позицию, выбрать все из них.

-- Решение
WITH class_avg_stats AS ( -- CTE, собирающий среднюю позицию по каждому классу (по всем гонкам всех автомобилей класса)
    SELECT -- выбираем
    c.class AS car_class, -- класс автомобиля
    AVG(r.position) AS class_avg_position -- средняя позиция по всем результатам в этом классе
    FROM cars AS c -- из таблицы автомобилей
    JOIN results AS r ON c.name = r.car -- соединяем с результатами по имени автомобиля
    GROUP BY c.class -- группируем по классу
),
min_class_avg AS ( -- CTE, собирающий минимальную среднюю позицию среди всех классов
    SELECT -- выбираем
    MIN(class_avg_position) AS min_avg_position -- наименьшее значение
    FROM class_avg_stats -- из статистики классов
),
best_classes AS ( -- CTE, собирающий классы, у которых средняя позиция равна минимальной
    SELECT -- выбираем
    cas.car_class -- только такие классы
    FROM class_avg_stats AS cas -- из статистики классов
    JOIN min_class_avg AS mca ON cas.class_avg_position = mca.min_avg_position -- условие равенства минимальной позиции
),
car_individual_stats AS ( -- CTE, собирающий индивидуальную статистику по каждому автомобилю для автомобилей из лучших классов
    SELECT -- выбираем
    r.car AS car_name, -- имя автомобиля
    c.class AS car_class, -- его класс
    AVG(r.position) AS average_position, -- средняя позиция автомобиля
    COUNT(*) AS race_count, -- количество гонок, в которых участвовал автомобиль
    cl.country AS car_country -- страна производства класса
    FROM results AS r -- из результатов
    JOIN cars AS c ON r.car = c.name -- соединяем с автомобилями
    JOIN classes AS cl ON c.class = cl.class -- соединяем с классами для страны
    WHERE c.class IN (SELECT car_class FROM best_classes) -- только автомобили из лучших классов
    GROUP BY r.car, c.class, cl.country -- группируем по автомобилю, классу, стране
),
class_total_races AS ( -- CTE, собирающий общее количество гонок (участий) для каждого лучшего класса
    SELECT -- выбираем
    c.class AS car_class, -- класс
    COUNT(*) AS total_races -- суммарное количество участий всех автомобилей класса в гонках
    FROM cars AS c -- из автомобилей
    JOIN results AS r ON c.name = r.car -- соединяем с результатами
    WHERE c.class IN (SELECT car_class FROM best_classes) -- только лучшие классы
    GROUP BY c.class -- группируем по классу
)
SELECT -- основной запрос, выводим информацию о каждом автомобиле из лучших классов
    cis.car_name, -- имя автомобиля
    cis.car_class, -- класс
    ROUND(cis.average_position, 4) AS average_position, -- средняя позиция (округлённая до 4 знаков)
    cis.race_count, -- количество гонок для этого автомобиля
    cis.car_country, -- страна производства
    ctr.total_races -- общее количество гонок (участий) для всего класса
FROM car_individual_stats AS cis -- из индивидуальной статистики автомобилей
JOIN class_total_races AS ctr ON cis.car_class = ctr.car_class -- присоединяем общее количество гонок по классу
ORDER BY cis.car_name; -- сортируем по имени автомобиля по алфавиту

-- Дополнительные комментарии:
-- Первый CTE (class_avg_stats) вычисляет среднюю позицию для каждого класса на основе всех гонок всех его автомобилей.
-- Второй CTE (min_class_avg) находит минимальное значение среди этих средних.
-- Третий CTE (best_classes) отбирает классы, у которых средняя позиция равна минимальной.
-- Четвертый CTE (car_individual_stats) считает для каждого автомобиля из этих классов его личную среднюю позицию, количество гонок и страну.
-- Пятый CTE (class_total_races) подсчитывает общее количество участий в гонках (сумму race_count) для каждого лучшего класса.
-- Основной запрос соединяет car_individual_stats и class_total_races по классу, выводит все требуемые поля.
-- ORDER BY cis.car_name обеспечивает порядок Ferrari 488, затем Ford Mustang, как в ожидаемом выводе.