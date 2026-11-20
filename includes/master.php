<?php

use Kriko\Controller\UserControl;

require_once __DIR__ . '/helpers.php';
require_once __DIR__ . '/session.php';

if (!function_exists('e')) {
    function e(mixed $valor): string
    {
        return htmlspecialchars((string) $valor, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
    }
}

if (!function_exists('masterEsc')) {
    function masterEsc(mixed $valor): string
    {
        return e($valor);
    }
}

if (($_SESSION['krikos_usuario']['perfil'] ?? '') !== 'MASTER') {
    header('Location: painel.php', true, 302);
    exit;
}

$erro = '';
$categorias = $produtos = $mesas = [];
try {
    require dirname(__DIR__) . '/bootstrap.php';
    $conexao = $entityManager->getConnection();
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        if (!is_string($_POST['csrf'] ?? null) || !hash_equals($_SESSION['krikos_csrf'], $_POST['csrf'])) {
            throw new RuntimeException('Atualize a página e tente novamente.');
        }
        $tipo = $_POST['tipo'] ?? '';
        if (!in_array($tipo, ['categoria', 'produto', 'mesa', 'administrador'], true)) {
            throw new RuntimeException('Operação inválida.');
        }
        $controle = new UserControl($entityManager);
        if ($tipo === 'categoria') {
            $controle->categoria(['nome' => $_POST['nome_categoria'] ?? '', 'descricao' => $_POST['descricao_categoria'] ?? '']);
        } elseif ($tipo === 'mesa') {
            $controle->mesa(['numeroMesa' => $_POST['numero_mesa'] ?? '', 'descricao' => $_POST['descricao_mesa'] ?? '', 'ativo' => $_POST['ativo'] ?? 'S']);
        } elseif ($tipo === 'administrador') {
            $senha = is_string($_POST['senha'] ?? null) ? (string) $_POST['senha'] : '';
            $email = filter_var($_POST['email'] ?? '', FILTER_VALIDATE_EMAIL);
            if (!$email || strlen($senha) < 8) {
                throw new InvalidArgumentException('Confira o e-mail e use uma senha com pelo menos 8 caracteres.');
            }
            $controle->administrador([
                'nome' => trim((string) ($_POST['nome'] ?? '')),
                'email' => $email,
                'senha' => password_hash($senha, PASSWORD_DEFAULT),
                'perfil' => (string) ($_POST['perfil'] ?? ''),
                'ativo' => 'S',
            ]);
        } else {
            $preco = $_POST['preco'] ?? '';
            if (!is_string($preco) || !preg_match('/\A[0-9]{1,7}(?:\.[0-9]{1,2})?\z/', $preco)) {
                throw new RuntimeException('Informe um preço válido.');
            }
            [$reais, $centavos] = array_pad(explode('.', $preco), 2, '0');
            $controle->produto([
                'categoria_id' => $_POST['id_categoria'] ?? '',
                'nome' => $_POST['nome_produto'] ?? '',
                'descricao' => $_POST['descricao_produto'] ?? '',
                'preco' => (int) $reais * 100 + (int) str_pad($centavos, 2, '0'),
                'ativo' => $_POST['ativo'] ?? 'S',
            ]);
        }
        header('Location: master.php', true, 303);
        exit;
    }
    $categorias = $conexao->fetchAllAssociative('SELECT * FROM categorias ORDER BY nome');
    $produtos = $conexao->fetchAllAssociative('SELECT p.*, c.nome AS categoria_nome FROM produtos p JOIN categorias c ON c.id = p.categoria ORDER BY p.nome');
    $mesas = $conexao->fetchAllAssociative('SELECT * FROM mesas ORDER BY numero_mesa');
} catch (Throwable $falha) {
    error_log('Master Krikos: ' . $falha->getMessage());
    $erro = 'Não foi possível concluir a operação. Confira os dados e a conexão com o banco.';
}
