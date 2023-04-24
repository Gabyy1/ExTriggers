CREATE DATABASE exTriggers
GO
USE exTriggers
GO
CREATE TABLE cliente (
codigo        INT            NOT NULL,
nome        VARCHAR(70)    NOT NULL
PRIMARY KEY(codigo)
)
GO
CREATE TABLE venda (
codigo_venda    INT                NOT NULL,
codigo_cliente    INT                NOT NULL,
valor_total        DECIMAL(7,2)    NOT NULL
PRIMARY KEY (codigo_venda)
FOREIGN KEY (codigo_cliente) REFERENCES cliente(codigo)
)
GO
CREATE TABLE pontos (
codigo_cliente    INT                    NOT NULL,
total_pontos    DECIMAL(4,1)        NOT NULL
PRIMARY KEY (codigo_cliente)
FOREIGN KEY (codigo_cliente) REFERENCES cliente(codigo)
)
Go
 


Insert Into cliente Values
(1, 'fulano')

 

Insert Into venda Values 
(1, 1, 500)

 

Select * From cliente

 

Update venda
Set valor_total = 2
Where valor_total = 200

 

-- Para não prejudicar a tabela venda, nenhum produto pode ser deletado, 
--mesmo que não venha mais a ser vendido
Create Trigger t_delvenda On Venda
For Delete
As
Begin
    RollBack Transaction
    RaisError('Não é possível deletar Produto', 16,1)
End

 

-- Para não prejudicar os relatórios e a contabilidade, 
--a tabela venda não pode ser alterada. 
-- Ao invés de alterar a tabela venda deve-se exibir uma tabela com 
--o nome do último cliente que comprou e o valor da última compra

 

Create Trigger t_upvenda On Venda 
For Update
As
Begin
    RollBack Transaction

 

    Create Table #Table (ucliente Varchar(50) , compra decimal(7,2))
    Select top 1 ucliente = nome, compra = valor_total From venda, cliente
    Group By venda.codigo_cliente, cliente.nome, venda.valor_total
    Order By codigo_cliente desc

 

    
    Select * From #Table

 

    RaisError('Não é possível atualizar tabela', 16, 1)
End

 

--Após a inserção de cada linha na tabela venda, 10% do total deverá ser transformado em pontos.
--Se o cliente ainda não estiver na tabela de pontos, deve ser inserido automaticamente após sua primeira compra
--Se o cliente atingir 1 ponto, deve receber uma mensagem (PRINT SQL Server) dizendo que ganhou
Create Trigger t_insvenda On venda
For Insert 
As
Begin
    Declare @total decimal(7,2),
			@codCliente int
	Set @total = 0
	Set @codCliente = (Select pontos.codigo_cliente From pontos Where pontos.codigo_cliente = (Select codigo_cliente From inserted))
	Set @total = ((Select Sum(venda.valor_total) From venda Where venda.codigo_cliente = (Select codigo_cliente From inserted))*0.1)

	If (@codCliente Is Null)
	Begin
		Insert Into pontos Values ((Select codigo_cliente From inserted), @total)
	End
	Else
	Begin
		Update pontos
		Set pontos.total_pontos = @total
		Where pontos.codigo_cliente = @codCliente
	End
	If ((Select pontos.total_pontos From pontos Where pontos.codigo_cliente = (Select codigo_cliente From inserted)) > 1)
	Begin
		Print('Parabéns!, Você ganhou um ponto')
	End
		Update venda
		Set venda.codigo_cliente = (Select codigo_cliente From inserted),
			venda.valor_total = (Select valor_total From inserted)
		Where venda.codigo_venda = 1
	End
