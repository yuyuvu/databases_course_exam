-- Решение задач по базе данных "Структура организации"

-- Задача 3.
-- Найти всех сотрудников, которые занимают роль менеджера и имеют подчиненных, то есть число подчиненных > 0.
-- Для каждого такого сотрудника вывести EmployeeID, имя, ManagerID, название отдела, название роли,
-- названия проектов через запятую, названия задач через запятую, общее количество подчиненных,
-- включая подчиненных их подчиненных.
-- Если проектов или задач нет, тогда NULL.
-- Использовать RECURSIVE.

-- Решение
WITH RECURSIVE subordinates_tree AS ( -- рекурсивный CTE для построения полного дерева подчинения
    SELECT -- первая часть, получаем всех сотрудников
    EmployeeID AS manager_id, -- идентификатор начального менеджера
    EmployeeID AS subordinate_id -- сам сотрудник как подчиненный, уровень 0
    FROM employees

    UNION ALL

    SELECT -- рекурсивная часть, находим подчиненных для каждого сотрудника
    st.manager_id, -- сохраняем исходного менеджера
    e.EmployeeID AS subordinate_id -- идентификатор подчиненного
    FROM employees AS e -- из таблицы сотрудников
    JOIN subordinates_tree AS st ON e.ManagerID = st.subordinate_id -- подчиненный того, кто уже в дереве
    WHERE e.ManagerID IS NOT NULL -- исключаем строки, где менеджер равен NULL 
),
subordinates_count AS ( -- CTE, собирающий количество всех подчиненных, включая косвенных, для каждого сотрудника
    SELECT -- выбираем
    manager_id AS EmployeeID, -- сотрудник-менеджер
    COUNT(subordinate_id) - 1 AS total_subordinates -- вычитаем 1, чтобы исключить самого себя
    FROM subordinates_tree -- из рекурсивного дерева
    GROUP BY manager_id -- группируем по менеджеру
),
tasks_count AS ( -- CTE, собирающий количество задач для каждого сотрудника (не используется напрямую, но для информации)
    SELECT -- выбираем
    AssignedTo, -- сотрудник
    COUNT(TaskID) AS total_tasks -- количество задач
    FROM tasks -- из таблицы задач
    GROUP BY AssignedTo -- группируем
)

SELECT -- основной запрос, выводим информацию о менеджерах, у которых есть подчиненные
e.EmployeeID AS EmployeeID, -- идентификатор сотрудника
e.Name AS EmployeeName, -- имя сотрудника
e.ManagerID AS ManagerID, -- идентификатор менеджера
d.DepartmentName AS DepartmentName, -- название отдела
r.RoleName AS RoleName, -- название роли
COALESCE( -- объединяем названия проектов через запятую, если проектов нет, тогда NULL
	(
	SELECT STRING_AGG(p.ProjectName, ', ' ORDER BY p.ProjectName)
	FROM projects AS p
	WHERE p.DepartmentID = e.DepartmentID
	), NULL
) AS ProjectNames, -- список проектов
COALESCE( -- объединяем названия задач через запятую, если задач нет, тогда NULL
	(
	SELECT STRING_AGG(t.TaskName, ', ' ORDER BY t.TaskID DESC)
	FROM tasks AS t
	WHERE t.AssignedTo = e.EmployeeID
	), NULL
) AS TaskNames, -- список задач
COALESCE(sc.total_subordinates, 0) AS TotalSubordinates -- общее количество подчиненных или 0, если их нет

FROM employees AS e -- из таблицы сотрудников
JOIN roles AS r ON e.RoleID = r.RoleID -- присоединяем роль
LEFT JOIN departments AS d ON e.DepartmentID = d.DepartmentID -- присоединяем отдел
LEFT JOIN subordinates_count AS sc ON e.EmployeeID = sc.EmployeeID -- присоединяем количество подчиненных
WHERE r.RoleName = 'Менеджер' -- только сотрудники с ролью менеджера
AND COALESCE(sc.total_subordinates, 0) > 0 -- и имеющие хотя бы одного подчиненного, включая косвенных
ORDER BY e.Name; -- сортируем по имени сотрудника

-- Дополнительные комментарии:
-- Рекурсивный CTE subordinates_tree строит для каждого сотрудника полное дерево подчиненных.
-- В первой части каждый сотрудник является менеджером для самого себя, уровень 0.
-- В рекурсивной части находим всех подчиненных прямых и косвенных для каждого начального сотрудника.
-- CTE subordinates_count подсчитывает количество подчиненных для каждого сотрудника,
-- вычитая 1, чтобы исключить самого сотрудника из подсчета.
-- Основной запрос выбирает только тех, у кого RoleName = 'Менеджер' и total_subordinates > 0.
-- Проекты и задачи формируются так же, как в задачах 1 и 2.
-- В конце осуществляется сортировка по имени сотрудника.